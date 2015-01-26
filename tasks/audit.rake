#
# audit.rake for Cheftasks
#
# Copyright::Jon Bogaty (jonbogaty.com)
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


namespace :audit do
  require 'rubygems'
  require 'chef'
  require 'json'
  require 'unix_crypt'
  require 'securerandom'
  require 'csv'
  require 'chef/rest'
  require 'chef/search/query'
  require 'benchmark'

  require File.join(File.dirname(__FILE__), 'lib', 'audit')

  config_file = File.exists?(File.join(Dir.getwd, '.chef', 'knife.rb')) ?
                File.join(Dir.getwd, '.chef', 'knife.rb') :
                File.join(File.expand_path('~'), '.chef', 'knife.rb')
  Chef::Config.from_file(config_file)

  Rake::TaskManager.record_task_metadata = true

  query = Chef::Search::Query.new
  csv_headers = ['Node(s)', 'Sample Node']

  desc "Generate roles audit"
  task :roles do |t, args|
    unless ENV['NO_ROLES']
      CSV.open('audits/roles.csv', 'w') do |csv|
        csv << ['Role'] + csv_headers

        d = Dir['roles/*.rb']
        i = 0
        l = d.length
        t = 0

        d.each do |p|
          t += Benchmark.realtime do
            role = Chef::Role.new
            role.from_file(p)

            nodes = query.search('node', "roles:#{role.name}")
            sample_node = (nodes[2] > 0)? nodes[0].sample.name: 'None'
            result_array = [role.name, nodes[2], sample_node]
            csv << result_array
          end

          print "\r#{i+=1}/#{l} roles [#{t.round(2)}s elapsed]"
        end
      end
    end

    unless ENV['NO_COOKBOOKS']
      csv_path = (ENV['DEFAULT_RECIPE_ONLY'])? 'audits/cookbooks_default_recipe_only.csv': 'audits/cookbooks_all_recipes.csv'
      CSV.open(csv_path, 'w') do |csv|
        csv << ['Cookbook', 'Recipe'] + csv_headers

        recipe_pattern = (ENV['DEFAULT_RECIPE_ONLY'])? 'site-cookbooks/*/recipes/default.rb': 'site-cookbooks/*/recipes/*.rb'
        d = Dir[recipe_pattern]
        i = 0
        l = d.length
        t = 0

        d.each do |p|
          t += Benchmark.realtime do
            cookbook = p.split('/')[1]
            recipe = File.basename(p, File.extname(p))
            nodes = query.search('node', "recipes:#{cookbook}\\:\\:#{recipe}")
            sample_node = (nodes[2] > 0)? nodes[0].sample.name: 'None'
            result_array = [cookbook, recipe, nodes[2], sample_node]
            csv << result_array
          end

          print "\r#{i+=1}/#{l} recipes [#{t.round(2)}s elapsed]"
        end
      end
    end
  end
end
