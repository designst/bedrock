require 'dotenv'

# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

# Load tasks from gems
require 'capistrano/wpcli'
require 'capistrano/composer'
require 'capistrano-db-tasks'
require 'capistrano/upload-config'

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
# Customize this path to change the location of your custom tasks.
Dir.glob('lib/capistrano/tasks/*.rb').each { |r| import r }