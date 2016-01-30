class Posgra::CLI::Grant < Thor
  include Posgra::CLI::Helper

  class_option :'include-schema'
  class_option :'exclude-schema'
  class_option :'include-role'
  class_option :'exclude-role'

  desc 'apply FILE', 'Apply grants'
  option :'dry-run', :type => :boolean, :default => false
  def apply(file)
    updated = client.apply_grants(file)

    unless updated
      Posgra::Logger.instance.info('No change'.intense_blue)
    end
  end

  desc 'export [FILE]', 'Export grants'
  def export(file = nil)
    dsl = client.export_grants

    if file.nil? or file == '-'
      puts dsl
    else
      open(file, 'wb') {|f| f.puts dsl }
    end
  end
end
