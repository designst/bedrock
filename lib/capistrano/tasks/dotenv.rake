require 'dotenv'

namespace :load do
  task :defaults do
    Dotenv.load ".env.#{fetch(:stage)}", ".env"
  end
end

namespace :dotenv do
  task :local do
    Dotenv.overload ".env"
  end

  task :stage do
    Dotenv.overload ".env.#{fetch(:stage)}"
  end
end