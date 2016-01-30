class Posgra::CLI::Role < Thor
  include Posgra::CLI::Helper

  class_option :'include-role'

  desc 'apply FILE', 'Apply roles'
  option :'dry-run', :type => :boolean, :default => false
  def apply(file)
    updated = client.apply_roles(file)

    unless updated
      Posgra::Logger.instance.info('No change'.intense_blue)
    end
  end

  desc 'export [FILE]', 'Export roles'
  def export(file = nil)
    dsl = client.export_roles

    if file.nil? or file == '-'
      puts dsl
    else
      open(file, 'wb') {|f| f.puts dsl }
    end
  end
end
