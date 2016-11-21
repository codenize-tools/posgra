class Posgra::CLI::Role < Thor
  include Posgra::CLI::Helper
  include Posgra::Logger::Helper

  class_option :'include-role'
  class_option :'exclude-role'
  class_option :'password-length'

  desc 'apply FILE', 'Apply roles'
  option :'dry-run', :type => :boolean, :default => false
  def apply(file)
    check_filename(file)
    updated = client.apply_roles(file)

    unless updated
      Posgra::Logger.instance.info('No change'.intense_blue)
    end
  end

  desc 'export [FILE]', 'Export roles'
  def export(file = nil)
    check_filename(file)
    dsl = client.export_roles

    if file.nil? or file == '-'
      puts dsl
    else
      log(:info, "Export Roles to `#{file}`")

      open(file, 'wb') do |f|
        f.puts Posgra::CLI::MAGIC_COMMENT
        f.puts dsl
      end
    end
  end
end
