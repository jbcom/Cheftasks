require 'rake'
require 'fileutils'
require 'rbconfig'

desc "Install ChefDK alongside Vagrant and VirtualBox for testing."
task :install do
  run %{which chef}
  if $?.success?
    print "ChefDK has already been installed."
  else
    case RbConfig::CONFIG['host_os']
    when /darwin|mac os/
      install_chefdk
    else
      print "Your platform is not supported yet by this script. Please download ChefDK from https://downloads.chef.io/chef-dk/ and manually install."
    end
  end

  success_msg("Cheftasks is ready to go.")
end

task :update do
  run %{git pull --rebase}

  if $?.success?
    Rake::Task["install"].execute
  else
    print "Pulling from remote failed. Status of repository is:"
    run %{git status}
  end
end

private
def install_chefdk
  run %{which brew}
  unless $?.success?
    print "Installing Homebrew, the OSX package manager."
    run %{ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"}
  end

  run %{brew install caskroom/cask/brew-cask}
  run %{brew update}
  run %{brew cask install chefdk vagrant virtualbox}
end
