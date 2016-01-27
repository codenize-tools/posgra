class Posgra::Client
  def initialize(options = {})
    @options = options
    # TODO:
    #@options[:identifier] ||= ...
    client = connect(options)
    @driver = Posgra::Driver.new(client, options)
  end

  def export(options = {})
    options = @options.merge(options)
    exported = Posgra::Exporter.export(@driver, options)

    if options[:split]
      dsl_h = Hash.new {|hash, key| hash[key] = {} }

      exported.each do |export_type, export_values|
        export_values.each do |item|
          if export_values.is_a?(Hash)
            key, value = item
            item = {key => value}
          else
            item = [item]
          end

          dsl = Posgra::DSL.convert({export_type => item}, options)
          dsl_h[export_type][key] = dsl
        end
      end

      dsl_h
    else
      Posgra::DSL.convert(exported, options)
    end
  end

  private

  def connect(options)
    connect_options = {}

    PG::Connection::CONNECT_ARGUMENT_ORDER.each do |key|
      value = options[key] || options[key.to_sym]

      if value
        connect_options[key] = value
      end
    end

    PGconn.connect(connect_options)
  end
end
