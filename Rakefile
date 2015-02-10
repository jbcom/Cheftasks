#
# Cheftasks for chef-repo directory
#
# COPYRIGHT:: Jon Bogaty (<jon@jonbogaty.com>)
# LICENSE:: Apache License, Version 2.0
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
#

namespace :ct do
  require 'benchmark'
  require 'chef'
  require 'chef/rest'
  require 'chef/search/query'
  require 'csv'
  require 'fileutils'
  require 'json'
  require 'net/ssh'
  require 'net/scp'
  require 'rake'
  require 'rbconfig'
  require 'rubygems'
  require 'securerandom'
  require 'unix_crypt'

  Rake::TaskManager.record_task_metadata = true

  # Load constants from rake config file.
  require File.join(File.dirname(__FILE__), 'config', 'cheftasks')

  Dir.glob( File.join(TOP_DIR, 'sitelib/*.rake') ) do |rf|
    load rf
  end
end

desc "Help for ChefTasks"
task :default do
  cn = ''
  Rake.application.tasks.each do |t|
    n, nt = t.name.split(':')[1..2]

    next unless nt
    if cn != n
      puts "ChefTasks :: #{n}".header_color
      cn = n
    end

    if t.arg_names.length > 0
      puts "\t#{nt}[#{t.arg_names.join(', ')}]".info_color.bold
    else
      puts "\t#{nt}".info_color.bold
    end

    puts "\t#{t.full_comment}".info_color if t.full_comment
  end
end

