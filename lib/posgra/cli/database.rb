class Posgra::CLI::Database < Thor
  include Posgra::CLI::Helper
  include Posgra::Logger::Helper

  DEFAULT_FILENAME = 'pg_dbgrants.rb'

  class_option :'include-role'
  class_option :'exclude-role'
  class_option :'include-database'
  class_option :'exclude-database'

  desc 'apply FILE', 'Apply database grants'
  option :'dry-run', :type => :boolean, :default => false
  def apply(file)
    check_fileanem(file)
    updated = client.apply_databases(file)

    unless updated
      Posgra::Logger.instance.info('No change'.intense_blue)
    end
  end

  desc 'export [FILE]', 'Export database grants'
  option :split, :type => :boolean, :default => false
  def export(file = nil)
    check_fileanem(file)
    dsl = client.export_databases

    if options[:split]
      file = DEFAULT_FILENAME unless file

      log(:info, 'Export Database Grants')
      requires = []

      dsl.each do |user, content|
        user = user.gsub(/\s+/, '_')
        user = '_' if user.empty?
        grant_file = "#{user}.rb"
        requires << grant_file
        log(:info, "  write `#{grant_file}`")

        open(grant_file, 'wb') do |f|
          f.puts Posgra::CLI::MAGIC_COMMENT
          f.puts content
        end
      end

      log(:info, "  write `#{file}`")

      open(file, 'wb') do |f|
        f.puts Posgra::CLI::MAGIC_COMMENT

        requires.each do |grant_file|
          f.puts "require '#{File.basename grant_file}'"
        end
      end
    else
      if file.nil? or file == '-'
        puts dsl
      else
        log(:info, "Export Database Grants to `#{file}`")

        open(file, 'wb') do |f|
          f.puts Posgra::CLI::MAGIC_COMMENT
          f.puts dsl
        end
      end
    end
  end
end
