module Posgra::CLI::Helper
  REGEXP_OPTIONS = [
    :include_schema,
    :exclude_schema,
    :include_role,
    :exclude_role,
    :include_object,
    :exclude_object,
  ]

  def check_fileanem(file)
    if file =~ /\A-.+/
      raise "Invalid failname: #{file}"
    end
  end

  def client
    client_options = {}
    String.colorize = options[:color]
    Posgra::Logger.instance.set_debug(options[:debug])

    options.each do |key, value|
      if key.to_s =~ /-/
        key = key.to_s.gsub('-', '_')
      end

      client_options[key.to_sym] = value if value
    end

    REGEXP_OPTIONS.each do |key|
      if client_options[key]
        client_options[key] = Regexp.new(client_options[key])
      end
    end

    client_options[:identifier] = Posgra::Identifier::Auto.new(options['account-output'], client_options)
    Posgra::Client.new(client_options)
  end
end
