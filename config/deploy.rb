# The user name of the remote
# server used for deployment
set :deploy_user, 'username'

# The name of the application
set :application, 'my_app_name'

# The URL of the repository
set :repo_url, 'git@example.com:me/my_repo.git'

# Set branch to always be master
# This could be overridden in a stage config file
set :branch, :master

# Use :debug for more verbose
# output when troubleshooting
set :log_level, :info

# The last n releases are kept
# for possible rollbacks
# The cleanup task detects outdated
# release folders and removes them
set :keep_releases, 10

# Deployment path variables
set :deploy_home, "/home/#{fetch(:deploy_user)}"
set :deploy_to, -> { "#{fetch(:deploy_home)}/www/#{fetch(:application)}/bedrock" }

# Temporary directory used during
# deployments to store data
# If you have a shared web host, this setting
# may need to be set (e.g. /home/user/tmp/capistrano)
set :tmp_dir, "#{fetch(:deploy_home)}/tmp/capistrano"

# Listed files will be symlinked into
# each release directory during deployment
set :linked_files, fetch(:linked_files, []).push(
    '.env', 'config/database.yml', 'web/.htaccess')

# Listed directories will be symlinked into
# each release directory during deployment
set :linked_dirs, fetch(:linked_dirs, []).push(
    'web/app/uploads')

# WP-CLI Configuration
# https://github.com/lavmeiker/capistrano-wpcli

# Get ENV variables of current stage
Dotenv.overload '.env'
set :wpcli_local_url, ENV['WP_HOME']
Dotenv.overload ".env.#{fetch(:stage)}"
set :wpcli_remote_url, ENV['WP_HOME']

set :wpcli_local_galleries_dir, 'web/app/galleries/'
set :wpcli_remote_galleries_dir, -> { shared_path.join('web/app/galleries/') }

# Upload Configuration
# https://github.com/rjocoleman/capistrano-upload-config
set :config_files, %w{.env web/.htaccess}
set :config_example_suffix, '.example'

# Database Backup Configuration
set :db_backup_path, shared_path.join('db/backup')
set :keep_db_backups, 10

# Database Tasks Configuration
# https://github.com/sgruhier/capistrano-db-tasks
set :db_remote_clean, true
set :local_rails_env, 'local'
set :skip_data_sync_confirm, true

# SSHKit command map for wp-cli execution
SSHKit.config.command_map[:wp] = "/usr/local/php56/bin/php #{shared_path.join('wp-cli.phar')}"

# SSHKit command map for composer execution
SSHKit.config.command_map[:composer] = "/usr/local/php56/bin/php #{shared_path.join('composer.phar')}"

# Capistrano Deploy-Flow Configuration
after 'deploy:starting', 'wpcli:install'
after 'deploy:starting', 'composer:install_executable'

before 'deploy:check:linked_files', 'config:init'
before 'deploy:check:linked_files', 'config:push'
before 'deploy:check:linked_files', 'config:database'

before 'deploy:updating', 'db:backup'

after 'deploy:publishing', 'wpcli:plugins:activate'
after 'deploy:publishing', 'wpcli:uploads:rsync:push'
after 'deploy:publishing', 'wpcli:update_option_paths'
after 'deploy:publishing', 'deploy:restart'