#
# Rakefile for Chef Server Repository
#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
#

require 'rubygems'
require 'chef'
require 'json'
require 'unix_crypt'
require 'securerandom'
require 'csv'

Rake::TaskManager.record_task_metadata = true

# Load constants from rake config file.
require File.join(File.dirname(__FILE__), 'config', 'rake')

# Detect the version control system and assign to $vcs. Used by the update
# task in chef_repo.rake (below). The install task calls update, so this
# is run whenever the repo is installed.
#
# Comment out these lines to skip the update.

if File.directory?(File.join(TOPDIR, ".svn"))
  $vcs = :svn
elsif File.directory?(File.join(TOPDIR, ".git"))
  $vcs = :git
end

# Load common, useful tasks from Chef.
# rake -T to see the tasks this loads.

load 'chef/tasks/chef_repo.rake'

desc "Bundle a single cookbook for distribution"
task :bundle_cookbook => [ :metadata ]
task :bundle_cookbook, :cookbook do |t, args|
  tarball_name = "#{args.cookbook}.tar.gz"
  temp_dir = File.join(Dir.tmpdir, "chef-upload-cookbooks")
  temp_cookbook_dir = File.join(temp_dir, args.cookbook)
  tarball_dir = File.join(TOPDIR, "pkgs")
  FileUtils.mkdir_p(tarball_dir)
  FileUtils.mkdir(temp_dir)
  FileUtils.mkdir(temp_cookbook_dir)

  child_folders = [ "cookbooks/#{args.cookbook}", "site-cookbooks/#{args.cookbook}" ]
  child_folders.each do |folder|
    file_path = File.join(TOPDIR, folder, ".")
    FileUtils.cp_r(file_path, temp_cookbook_dir) if File.directory?(file_path)
  end

  system("tar", "-C", temp_dir, "-cvzf", File.join(tarball_dir, tarball_name), "#{args.cookbook}")

  FileUtils.rm_rf temp_dir
end

desc "Prune passwords for non-sysadmins"
task :user_prune_passwords do |t, args|
  Dir['data_bags/users/*.json'].each do |databag_file|
    user_data = JSON.parse(File.read(databag_file))

    if user_data['groups'] and !user_data['groups'].include?('sysadmin')
      user_data.delete('password')
      user_json = JSON.pretty_generate(user_data)
      File.open(databag_file, 'w') { |f| f.write(user_json) }
    end
  end
end

desc "Generate default passwords for all users"
task :user_default_passwords do |t, args|
  CSV.open('data_bags/default_passwords.csv', 'w') do |csv|
    Dir['data_bags/users/*.json'].each do |databag_file|
      user_data = JSON.parse(File.read(databag_file))

      if user_data["password"]
        print "Password already set for #{user_data['id']}"
      else
        plaintext_password = SecureRandom.hex(16)
        csv << [ user_data['id'], plaintext_password ]
        user_data['password'] = UnixCrypt::SHA512.build(plaintext_password)

        user_json = JSON.pretty_generate(user_data)

        File.open(databag_file, 'w') { |f| f.write(user_json) }
      end
    end
  end
end

desc "Set custom password for a user databag (If password is not speciified a randomly generated one wil be used)"
task :user_custom_password, :user, :password do |t, args|
  databag_file = "data_bags/users/#{args.user}.json"

  if File.exist?(databag_file)
    user_data = JSON.parse(File.read(databag_file))

    if args.password
      user_password = args.password
    else
      user_password = SecureRandom.hex(16)
    end

    user_data['password'] = UnixCrypt::SHA512.build(user_password)
    user_json = JSON.pretty_generate(user_data)

    File.open(databag_file, 'w') { |f| f.write(user_json) }
    print "Password set to #{user_password}"
  else
    print "User not found by that name. Check name of JSON file and try again."
  end
end

desc "Add a public or private key to a user databag"
task :user_save_rsa, :rsa_file, :user do |t, args|
  if File.exist?(args.rsa_file)
    rsa_key = File.read(args.rsa_file)
    databag_file = "data_bags/users/#{args.user}.json"

    if File.exist?(databag_file)
      user_data = JSON.parse(File.read(databag_file))
    else
      user_data = {}
    end

    if File.extname(args.rsa_file) == ".pub"
      print "Saving public key"
      if user_data["ssh_keys"]
        user_data["ssh_keys"] << rsa_key.chomp!
      else
        user_data["ssh_keys"] = ["#{rsa_key.chomp!}"]
      end
    else
      print "Saving private key"
      user_data["ssh_private_key"] = rsa_key.chomp!
    end

    user_json = JSON.pretty_generate(user_data)

    if File.exist?(databag_file)
      File.open(databag_file, "w") { |f| f.write(user_json) }
    else
      print JSON.pretty_generate(user_json)
    end
  else
    print "Could not open #{args.rsa_file} for reading. Make sure this is the full path to a private key or public (.pub) key"
  end
end

desc "Bring up, reconfigure, or update a Chef Server\nOptional environment variables:\nKNIFE_GENERATE_ONLY=true (Outputs command for generating knife.rb)\nUSE_SUDO=true\nCHEF_SERVER_CTL_FLAG=subcommand1,..,subcommandN (Interfaces with chef_server_ctl on remote host)\n[See https://docs.chef.io/ctl_chef_server.html]\nmultiple subcommands will be executed in sequence"
task :chef_server_ctl, :fqdn, :user, :key_file do |t, args|
  require 'net/ssh'
  require 'net/scp'

  if args[:fqdn]
    current_dir = File.dirname(__FILE__)
    home_dir    = ENV['HOME'] || ENV['HOMEDRIVE']
    chef_dotfiles_dir = File.join(current_dir, '.chef')
    chef_fqdn_knife_file = File.join(chef_dotfiles_dir, "knife.#{args[:fqdn]}.rb")
    chef_server_pem_dir =  File.join(chef_dotfiles_dir, args[:fqdn])
    FileUtils.mkdir_p(chef_server_pem_dir)

    args[:user] ||= `whoami`
    args[:key_file] ||= "##{home_dir}/.ssh/id_rsa"

    sudo_cmd = ENV['USE_SUDO'] ? "sudo " : ""

    unless ENV['KNIFE_GENERATE_ONLY']
      Net::SSH.start(args[:fqdn], args[:user], :keys => [args[:key_file]]) do |session|
        print session.exec!("#{sudo_cmd}/usr/bin/yum localinstall -y https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-server-11.1.6-1.el6.x86_64.rpm")
        
        if ENV['CHEF_SERVER_CTL_FLAG']
          ENV['CHEF_SERVER_CTL_FLAG'].split(',').each do |f|
            print session.exec!("#{sudo_cmd}/usr/bin/chef-server-ctl #{f}")
            
            if f == "reconfigure"

              session.scp.download!('/etc/chef-server/', chef_server_pem_dir, :recursive => true) do |ch, name, sent, total|
                print "#{name}: #{sent}/#{total}"
              end
            end
          end
        end

        session.loop
      end
    end

    print "Okay! Now run:\nknife configure -c #{chef_fqdn_knife_file} --admin-client-name admin --admin-client-key #{File.join(chef_server_pem_dir, 'admin.pem')} -r #{current_dir} --validation-client-name chef-validator --validation-key #{File.join(chef_server_pem_dir, 'chef-validator.pem')}\n\nWhich will generate a knife configuration for the new server"
  else
    print t.full_comment
  end
end
