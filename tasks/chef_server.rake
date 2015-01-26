desc "Manipulate a Chef Server with chef_server_ctl commands.\nOptional environment variables:\nKNIFE_GENERATE_ONLY=true (Outputs command for generating knife.rb)\nUSE_SUDO=true\nCHEF_SERVER_CTL_FLAG=subcommand1,..,subcommandN (Interfaces with chef_server_ctl on remote host)\n[See https://docs.chef.io/ctl_chef_server.html]\nmultiple subcommands will be executed in sequence"
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
