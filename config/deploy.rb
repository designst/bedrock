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

# Use :debug for more verbose output when troubleshooting
set :log_level, :info

# Apache users with .htaccess files:
# it needs to be added to linked_files so it persists across deploys:
# set :linked_files, fetch(:linked_files, []).push('.env', 'web/.htaccess')
set :linked_files, fetch(:linked_files, []).push('.env', 'config/database.yml', 'web/.htaccess')
set :linked_dirs, fetch(:linked_dirs, []).push('web/app/uploads')

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
            #execute :killall, -9, 'php-cgi'
            execute :touch, release_path.join('tmp/restart.txt')
        end
    end
end

# The above restart task is not run by default
# Uncomment the following line to run it on deploys if needed
# after 'deploy:publishing', 'deploy:restart'

namespace :deploy do
  desc 'Update WordPress template root paths to point to the new release'
  task :update_option_paths do
    on roles(:app) do
      within fetch(:release_path) do
        if test :wp, :core, 'is-installed'
          [:stylesheet_root, :template_root].each do |option|
            # Only change the value if it's an absolute path
            # i.e. The relative path "/themes" must remain unchanged
            # Also, the option might not be set, in which case we leave it like that
            value = capture :wp, :option, :get, option, raise_on_non_zero_exit: false
            if value != '' && value != '/themes'
              execute :wp, :option, :set, option, fetch(:release_path).join('web/wp/wp-content/themes')
            end
          end
        end
      end
    end
  end
end

# The above update_option_paths task is not run by default
# Note that you need to have WP-CLI installed on your server
# Uncomment the following line to run it on deploys if needed
# after 'deploy:publishing', 'deploy:update_option_paths'