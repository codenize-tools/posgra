class Posgra::CLI::App < Thor
  class_option :host, :default => 'localhost'
  class_option :port, :type => :numeric, :default => 5432
  class_option :dbname, :default => 'postgres'
  class_option :user
  class_option :password
  class_option :'account-output', :default => 'account.csv'
  class_option :color, :type => :boolean, :default => true
  class_option :debug, :type => :boolean, :default => false

  desc 'role SUBCOMMAND', 'Manage roles'
  subcommand :role, Posgra::CLI::Role

  desc 'grant SUBCOMMAND', 'Manage grants'
  subcommand :grant, Posgra::CLI::Grant
end
