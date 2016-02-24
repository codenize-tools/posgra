class Posgra::CLI::App < Thor
  class_option :host, :default => 'localhost', :aliases => '-h'
  class_option :port, :type => :numeric, :default => 5432, :aliases => '-p'
  class_option :dbname, :default => 'postgres', :aliases => '-d'
  class_option :user, :aliases => '-U'
  class_option :password, :aliases => '-P'
  class_option :'account-output', :default => 'account.csv'
  class_option :color, :type => :boolean, :default => true
  class_option :debug, :type => :boolean, :default => false

  desc 'role SUBCOMMAND', 'Manage roles'
  subcommand :role, Posgra::CLI::Role

  desc 'grant SUBCOMMAND', 'Manage grants'
  subcommand :grant, Posgra::CLI::Grant

  desc 'database SUBCOMMAND', 'Manage database grants'
  subcommand :database, Posgra::CLI::Database
end
