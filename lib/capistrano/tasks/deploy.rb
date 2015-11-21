namespace :deploy do
  task :all do
    # Push local database to server
    after 'deploy:updated', 'db:push'
  end

  namespace :assets do
    desc 'Execute gulp and build production asset files'
    task :compile do
      run_locally do
        within fetch(:local_theme_path) do
          execute :gulp, 'build:production'
        end
      end
    end

    desc 'Upload the built asset files to remote server'
    task :upload do
      on roles(:web) do
        # Remote Paths (Lazy-load until actual deploy)
        set :remote_build_path, -> { release_path.join(fetch(:theme_path)).join('assets') }
        set :remote_dist_path, -> { release_path.join(fetch(:theme_path)).join('assets') }

        upload! fetch(:local_build_path).to_s, fetch(:remote_build_path), recursive: true
        upload! fetch(:local_dist_path).to_s, fetch(:remote_dist_path), recursive: true
      end
    end

    task run: %w(compile upload)
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here:
      execute :pkill, -9, 'php-cgi; true'
    end
  end
end