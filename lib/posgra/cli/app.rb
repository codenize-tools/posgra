class Posgra::CLI::App < Thor
  class_option :host, :default => ENV['POSGRA_DB_HOST'] || 'localhost', :aliases => '-h'
  class_option :port, :type => :numeric, :default => ENV['POSGRA_DB_PORT'] || 5432, :aliases => '-p'
  class_option :dbname, :default => ENV['POSGRA_DB_DATABASE'] || 'postgres', :aliases => '-d'
  class_option :user, :default => ENV['POSGRA_DB_USER'], :aliases => '-U'
  class_option :password, :default => ENV['POSGRA_DB_PASSWORD'], :aliases => '-P'
  class_option :'account-output', :default => ENV['POSGRA_ACCOUNT_FILEPATH'] || 'account.csv'
  class_option :color, :type => :boolean, :default => true
  class_option :debug, :type => :boolean, :default => false

  desc 'role SUBCOMMAND', 'Manage roles'
  subcommand :role, Posgra::CLI::Role

  desc 'grant SUBCOMMAND', 'Manage grants'
  subcommand :grant, Posgra::CLI::Grant

  desc 'database SUBCOMMAND', 'Manage database grants'
  subcommand :database, Posgra::CLI::Database
end
