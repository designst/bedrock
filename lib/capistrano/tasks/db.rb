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

  desc 'Fetches remote database and stores it'
  task :fetch do
    on roles(:db) do
      remote_db = Database::Remote.new(self)

      begin
        remote_db.dump.download
      ensure
        remote_db.clean_dump_if_needed
      end
    end
  end

  task :backup do
    on roles(:db) do |host|
      execute :mkdir, "-p #{fetch(:db_backup_path)}"
      basename = 'database'

      username, password, database, host = get_remote_database_config(fetch(:stage))
      debug "#{username}, #{password}, #{database}, #{host}"

      filename = "#{basename}_#{fetch(:stage)}_#{database}_#{Time.now.strftime '%Y-%m-%d-%H%M%S'}.sql.bz2"
      debug "We will backup to file: #{fetch(:db_backup_path)}/#{filename}"

      hostcmd = host.nil? ? '' : "-h #{host}"
      execute :mysqldump, "-u #{username} --password='#{password}' --databases #{database} #{hostcmd} | bzip2 -9 > #{fetch(:db_backup_path)}/#{filename}"

      purge_old_backups "#{basename}", "#{fetch(:db_backup_path)}"
    end
  end

  def get_remote_database_config(db)
    #remote_config = capture("cat #{current_path}/config/database.yml")
    #database = YAML::load(remote_config)

    #return database["#{db}"]['username'], database["#{db}"]['password'], database["#{db}"]['database'],
    #    database["#{db}"]['host']

    return "#{ENV['DB_USER']}", "#{ENV['DB_PASSWORD']}", "#{ENV['DB_NAME']}", "#{ENV['DB_HOST']}"
  end

  def purge_old_backups(basename, backup_path)
    max_keep = fetch(:keep_db_backups, 5).to_i
    backup_files = capture("ls -t #{backup_path}/#{basename}*").split.reverse

    if max_keep >= backup_files.length
      info "No old database backups to clean up"
    else
      info "Keep #{max_keep} of #{backup_files.length} database backups"
      delete_backups = (backup_files - backup_files.last(max_keep)).join(" ")
      execute :rm, "-rf #{delete_backups}"
    end
  end

  task :configure do
    on roles(:db) do
      db_config = <<-EOF
base: &base
  adapter: mysql2
  encoding: utf8
  reconnect: false
  pool: 5
  host: <%= ENV['DB_HOST'] %>
  database: <%= ENV['DB_NAME'] %>
  username: <%= ENV['DB_USER'] %>
  password: <%= ENV['DB_PASSWORD'] %>
staging:
  <<: *base
production:
  <<: *base
local:
  <<: *base
  host: <%= ENV['DB_LOCALHOST'] %>
  database: <%= ENV['DB_LOCALNAME'] %>
  username: <%= ENV['DB_LOCALUSER'] %>
  password: <%= ENV['DB_LOCALPASSWORD'] %>
      EOF

      execute "mkdir -p #{current_path}/db"
      execute "mkdir -p #{shared_path}/config"
      upload! StringIO.new(db_config), "#{shared_path}/config/database.yml"
    end
  end
end