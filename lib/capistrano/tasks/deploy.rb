namespace :deploy do
  # Theme path
  set :theme_path, Pathname.new('web/app/themes').join(fetch(:theme_name))

  # Local Paths
  set :local_theme_path, Pathname.new(File.dirname(__FILE__)).join('../').join(fetch(:theme_path))
  set :local_build_path, fetch(:local_theme_path).join('assets/build')
  set :local_dist_path, fetch(:local_theme_path).join('assets/dist')

  task :compile do
    run_locally do
      within fetch(:local_theme_path) do
        execute :gulp, 'build:production'
      end
    end
  end

  task :copy do
    on roles(:web) do
      # Remote Paths (Lazy-load until actual deploy)
      set :remote_build_path, -> { release_path.join(fetch(:theme_path)).join('assets') }
      set :remote_dist_path, -> { release_path.join(fetch(:theme_path)).join('assets') }

      upload! fetch(:local_build_path).to_s, fetch(:remote_build_path), recursive: true
      upload! fetch(:local_dist_path).to_s, fetch(:remote_dist_path), recursive: true
    end
  end

  task assets: %w(compile copy)

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here:
      execute :pkill, -9, 'php-cgi; true'
    end
  end
end