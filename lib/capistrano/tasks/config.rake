# Load upload shared config tasks
require 'capistrano/upload-config'

# Tasks
namespace :config do
  desc 'Initialize local config files'
  task :local do
    run_locally do
      fetch(:config_files).each do |config|
        if File.exists?(config)
          warn "Already Exists: #{config}"
        else
          example_suffix = fetch(:config_example_suffix, '')
          if File.exists?("#{config}#{example_suffix}")
            FileUtils.cp "#{config}#{example_suffix}", config
            info "Copied: #{config}#{example_suffix} to #{config}"
          else
            File.open(config, "w") {}
            info "Created: #{config} as empty file"
          end
        end
      end
    end
  end

  desc 'Push database configuration to server'
  task :database do
    on release_roles :all do
      within shared_path do
        config = 'config/database.yml'
        if File.exists?(config)
          info "Uploading config #{config}"
          upload! StringIO.new(IO.read(config)), File.join(shared_path, config)
        else
          fail "#{config} doesn't exist"
        end
      end
    end
  end

  desc 'Manage Permission'
  task :permission do
    on roles(:app) do
      execute "chmod 644 #{shared_path}/web/.htaccess"
    end
  end
end

before 'deploy:check:linked_files', 'config:init'
before 'deploy:check:linked_files', 'config:push'
before 'deploy:check:linked_files', 'config:database'

after 'deploy:check:linked_files', 'config:permission'