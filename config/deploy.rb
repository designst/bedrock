# The user name of the remote
# server used for deployment
set :deploy_user, 'username'

# The name of the application
set :application, 'my_app_name'
set :theme_name, 'wp_theme_name'

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
    '.env', '.htpasswd', 'auth.json', 'config/database.yml', 'web/.htaccess')

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
set :config_files, %w{.env .htpasswd auth.json web/.htaccess}
set :config_example_suffix, '.example'

# File Permissions Configuration
set :file_permissions_paths, %w{.htpasswd web/.htaccess}
set :file_permissions_chmod_mode, '644'

# Database Backup Configuration
set :db_backup_path, shared_path.join('db/backup')
set :keep_db_backups, 10

# Database Tasks Configuration
# https://github.com/sgruhier/capistrano-db-tasks
set :db_remote_clean, true
set :local_rails_env, 'local'
set :skip_data_sync_confirm, true

# Prepare asset paths
# Build theme path
set :theme_path, Pathname.new('web/app/themes').join(fetch(:theme_name))

# Build local theme path
set :local_theme_path, Pathname.new(File.dirname(__FILE__)).join('..').join(fetch(:theme_path))

# Set local build & dist asset paths
set :local_build_path, fetch(:local_theme_path).join('assets/build')
set :local_dist_path, fetch(:local_theme_path).join('assets/dist')

# SSHKit command map for wp-cli execution
SSHKit.config.command_map[:wp] = "/usr/local/php56/bin/php #{shared_path.join('wp-cli.phar')}"

# SSHKit command map for composer execution
SSHKit.config.command_map[:composer] = "/usr/local/php56/bin/php #{shared_path.join('composer.phar')}"

# ------------------------------------
# Capistrano Deploy-Flow Configuration
# ------------------------------------

# Install wpcli and composer executables
after 'deploy:starting', 'wpcli:install'
after 'deploy:starting', 'composer:install_executable'

# Initialize and push configuration files
before 'deploy:check:linked_files', 'config:init'
before 'deploy:check:linked_files', 'config:push'
before 'deploy:check:linked_files', 'config:database'

# Set correct linked files permissions
after 'deploy:check:linked_files', 'config:permission'

# Create database dump and download locally
before 'deploy:updating', 'db:remote:backup'

# Compile asset files and push to server
after 'deploy:updating', 'deploy:assets:run'

# Push uploads directory to server
after 'deploy:updated', 'wpcli:uploads:rsync:push'

# Activate plugins
after 'deploy:updated', 'wpcli:plugins:activate'

# Update theme options with new url
after 'deploy:updated', 'wpcli:update_option_paths'

# Restart running php processes
after 'deploy:publishing', 'deploy:restart'