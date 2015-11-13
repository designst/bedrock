namespace :ds do
  namespace :install do
    desc 'Download WP-CLI'
    task :wpcli do
      on roles(:app) do
        within shared_path do
          execute :curl, "-O", "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
          execute :chmod, '+x', "wp-cli.phar"
        end
      end
    end
  end

  namespace :check do
    task :git do
      on roles(:app) do
        begin
          execute :git, :status
        rescue
          execute :git, :init
        end
      end
    end
  end

  namespace :db do
    task :pull do
      invoke 'db:pull'

      remote_wp_home = ENV['WP_HOME']
      invoke 'dotenv:local'
      local_wp_home = ENV['WP_HOME']

      run_locally do
        execute :wplocal, "search-replace", remote_wp_home, local_wp_home, fetch(:wpcli_args) || "--skip-columns=guid"
      end
    end

    task :push do
      invoke 'db:push'

      invoke 'dotenv:local'
      local_wp_home = ENV['WP_HOME']
      invoke 'dotenv:stage'
      remote_wp_home = ENV['WP_HOME']

      on roles(:app) do
        within release_path do
          execute :wp, "search-replace", local_wp_home, remote_wp_home, fetch(:wpcli_args) || "--skip-columns=guid"
        end
      end
    end
  end
end

before 'deploy:check', 'ds:check:git'
after 'deploy:started', 'ds:install:wpcli'