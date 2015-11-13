require 'capistrano/wpcli'

namespace :wpcli do
  namespace :plugins do
    desc 'Activate Installed Plugins'
    task :activate do
      on roles(:app) do
        within release_path do
          if !fetch(:wpcli_required_plugins).nil?
            fetch(:wpcli_required_plugins).each do |plugin|
              execute :wp, :plugin, :activate, plugin
            end
          end
        end
      end
    end
  end

  namespace :galleries do
    desc 'Push local galleries delta to remote machine'
    task :push do
      roles(:all).each do |role|
        run_locally do
          execute :rsync, fetch(:wpcli_rsync_options), fetch(:wpcli_local_galleries_dir), "#{role.user}@#{role.hostname}:#{fetch(:wpcli_remote_galleries_dir)}"
        end
      end
    end

    desc 'Pull remote galleries delta to local machine'
    task :pull do
      roles(:all).each do |role|
        run_locally do
          execute :rsync, fetch(:wpcli_rsync_options), "#{role.user}@#{role.hostname}:#{fetch(:wpcli_remote_galleries_dir)}", fetch(:wpcli_local_galleries_dir)
        end
      end
    end
  end

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

            if value != '' and value != '/themes'
              execute :wp, :option, :set, option, fetch(:release_path).join('web/wp/wp-content/themes')
            end
          end
        end
      end
    end
  end
end

after 'deploy:published', 'wpcli:plugins:activate'
after 'deploy:published', 'wpcli:uploads:rsync:push'

# The above update_option task is not run by default
# Note that you need to have WP-CLI installed on your server
# Uncomment the following line to run it on deploys if needed
after 'deploy:publishing', 'wpcli:update_option_paths'