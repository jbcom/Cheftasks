# Configure the Rakefile's tasks.

# License for new Cookbooks
# Can be :apachev2 or :none
NEW_COOKBOOK_LICENSE = :apachev2

# The top of the repository checkout
TOPDIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))

# Where to store certificates generated with ssl_cert
CADIR = File.expand_path(File.join(TOPDIR, "certificates"))

# Required Gems for Cheftasks
BREW_LIBS = [
]

CHEF_GEMS = [
  'unix-crypt'
]
