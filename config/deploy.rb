set :application, 'my_app_name'
set :deploy_user, 'username'

set :deploy_home, "/home/#{fetch(:deploy_user)}"
set :repo_url, 'git@example.com:me/my_repo.git'

set :use_sudo, false

# Branch options
# Prompts for the branch name (defaults to current branch)
#ask :branch, -> { `git rev-parse --abbrev-ref HEAD`.chomp }

# Hardcodes branch to always be master
# This could be overridden in a stage config file
set :branch, :master

set :tmp_dir, "#{fetch(:deploy_home)}/tmp"
set :deploy_to, -> { "#{fetch(:deploy_home)}/www/#{fetch(:application)}/bedrock" }
set :deploy_via, :remote_cache

set :log_level, :info

# Apache users with .htaccess files:
# it needs to be added to linked_files so it persists across deploys:
set :linked_files, %w{.env config/database.yml web/.htaccess}
set :linked_dirs, %w{web/app/uploads}

# Upload Configs
set :config_files, %w{.env web/.htaccess}
set :config_example_suffix, '.example'

# Database Backup
set :db_backup_path, "#{shared_path}/db/backup"
set :keep_db_backups, 10

SSHKit.config.command_map[:wp] = "php -d memory_limit=512M -d allow_url_fopen=1 -d \
suhosin.executor.include.whitelist=phar #{fetch(:tmp_dir)}/wp-cli.phar"

SSHKit.config.command_map[:wplocal] = :wp

SSHKit.config.command_map[:composer] = "php -d memory_limit=512M -d allow_url_fopen=1 -d \
suhosin.executor.include.whitelist=phar #{fetch(:tmp_dir)}/composer.phar"

# Fix tar execution on freebsd system
module GitStrategy
    require 'capistrano/git'
    include Capistrano::Git::DefaultStrategy
    def release
        git :archive, fetch(:branch), '| tar -x -f - -C', release_path
    end
end

set :git_strategy, GitStrategy

namespace :deploy do
    desc 'Restart application'
    task :restart do
        on roles(:app), in: :sequence, wait: 5 do
            # Your restart mechanism here, for example:
            # execute :service, :nginx, :reload
            execute :killall, -9, 'php-cgi'
        end
    end
end

# The above restart task is not run by default
# Uncomment the following line to run it on deploys if needed
after 'deploy:publishing', 'deploy:restart'