# Automatic Database Backups with Capistrano 3
# http://www.railsfever.com/blogs/automatic-database-backups-with-capistrano-3

namespace :db do
  desc 'Extend the db:pull task with wpcli commands to search-replace urls'
  task :pull do
    on roles(:db) do
      run_locally do
        execute :wp, 'search-replace', fetch(:wpcli_remote_url), fetch(:wpcli_local_url),
                fetch(:wpcli_args) || '--skip-columns=guid'
      end
    end
  end

  desc 'Extend the db:push task with wpcli commands to search-replace urls'
  task :push do
    on roles(:db) do
      within release_path do
        execute :wp, 'search-replace', fetch(:wpcli_local_url), fetch(:wpcli_remote_url),
                fetch(:wpcli_args) || '--skip-columns=guid'
      end
    end
  end

  namespace :local do
    desc 'Backup local database'
    task :backup do
      run_locally do
        config = capture('cat config/database.yml')
        config = YAML.load(ERB.new(config).result)['local']

        backup config, 'db'
      end
    end

    desc 'Restore local database'
    task :restore do
      run_locally do
        # todo: implement restore functionality
      end
    end
  end

  namespace :remote do
    desc 'Backup remote database'
    task :backup do
      on roles(:db) do
        within shared_path do
          config = capture("cat #{shared_path}/config/database.yml")
          config = YAML.load(ERB.new(config).result)[fetch(:stage).to_s]

          backup config, fetch(:db_backup_path)
        end
      end
    end
  end

  def backup(config, backup_path)
    execute :mkdir, '-p', backup_path

    basename = "#{config['database']}_"
    filename = "#{basename}#{Time.now.strftime('%Y-%m-%d-%H%M%S')}.sql.bz2"
    execute "mysqldump -u #{config['username']} -p#{config['password']} #{config['database']}
            --lock-tables=false | bzip2 -9 > #{backup_path}/#{filename}"

    purge_old_backups basename, backup_path
  end

  def purge_old_backups(basename, backup_path)
    max_keep = fetch(:keep_db_backups, 5).to_i
    backup_files = capture("ls -t #{backup_path}/#{basename}*").split.reverse

    if max_keep < backup_files.length
      delete_backups = (backup_files - backup_files.last(max_keep)).join(' ')

      execute :rm, "-rf #{delete_backups}"
    end
  end
end