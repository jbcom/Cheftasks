# Configure the Rakefile's tasks.

# The top of the repository checkout
TOP_DIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))

# Data bag defaults
DEFAULT_PASSWORD_LENGTH=16

# Required Gems for Cheftasks
BREW_LIBS = [
]

CHEF_GEMS = [
  'unix-crypt'
]
