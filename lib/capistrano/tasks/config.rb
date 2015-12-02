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
            File.open(config, 'w') {}
            info "Created: #{config} as empty file"
          end
        end
      end
    end
  end

  desc 'Push database.yml configuration to server'
  task :database do
    on release_roles(:all) do
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

  desc 'Set permissions of configured files and directories'
  task :permission do
    on release_roles(:all) do
      within shared_path do
        execute :chmod, '-R', fetch(:file_permissions_chmod_mode), fetch(:file_permissions_paths)
      end
    end
  end
end