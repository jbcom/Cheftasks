# Configure the Rakefile's tasks.
# Setup preferences as necessary for your infrastructure

# Translates to the root of chef-repo when symlinked
HOME_DIR = ENV['HOME'] || File.expand_path('~')
TOP_DIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))
DATABAGS_DIR = File.expand_path(File.join(TOP_DIR, 'data_bags'))
COOKBOOKS_DIR = File.expand_path(File.join(TOP_DIR, 'cookbooks'))
SITE_COOKBOOK_NAME = 'infrastructure'
SITE_COOKBOOK = File.expand_path(COOKBOOKS_DIR, SITE_COOKBOOK_NAME)

# Chef config
KNIFE_CONFIG_FILE = File.exist?(File.join(TOP_DIR, '.chef', 'knife.rb')) ?
  File.join(TOP_DIR, '.chef', 'knife.rb') :
  File.join(HOME_DIR, '.chef', 'knife.rb')

Chef::Config.from_file(KNIFE_CONFIG_FILE) if File.exist?(KNIFE_CONFIG_FILE)

# Data bag defaults
DEFAULT_PASSWORD_LENGTH=16

# Operating system and package manager
case RbConfig::CONFIG['host_os']
when /darwin|mac os/
  MANAGER = 'brew'
  MANAGER_GUI = 'brew cask'
  ELEVATE = false
  ACTION = 'install'
when /linux/
  ELEVATE = true
  ACTION = 'install y'

  run %{which apt-get}
  if $?.success?
    MANAGER = 'apt-get'
    MANAGER_GUI = 'apt-get'
  else
    run %{which yum}
    if $?.success?
      MANAGER = 'yum'
      MANAGER_GUI = 'yum'
    end
  end
end

# Required Gems for Cheftasks
BREW_LIBS = [
]

CHEF_GEMS = [
  'unix-crypt'
]

# Add some colorization for output
class String
  def warning_color;  "\033[31m#{self}\033[0m" end
  def header_color;   "\033[32m#{self}\033[0m" end
  def info_color;     "\033[36m#{self}\033[0m" end
  def bold;           "\033[1m#{self}\033[22m" end
end
