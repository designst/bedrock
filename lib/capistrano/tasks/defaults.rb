namespace :load do
  desc 'Load default ENV variables of the current stage'
  task :defaults do
    # noinspection RubyResolve
    Dotenv.load ".env.#{fetch(:stage)}", '.env'
  end
end