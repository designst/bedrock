namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here:
      execute :pkill, -9, 'php-cgi; true'
    end
  end
end