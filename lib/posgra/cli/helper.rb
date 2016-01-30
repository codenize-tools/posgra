module Posgra::CLI::Helper
  REGEXP_OPTIONS = [
    :include_schema,
    :include_role,
  ]

  def client
    client_options = {}
    String.colorize = options[:color]

    options.each do |key, value|
      if key.to_s =~ /-/
        key = key.to_s.gsub('-', '_').to_sym
      end

      client_options[key] = value if value
    end

    REGEXP_OPTIONS.each do |key|
      if client_options[key]
        client_options[key] = Regexp.new(client_options[key])
      end
    end

    client_options[:identifier] = Posgra::Identifier::Auto.new(options['account-output'])
    Posgra::Client.new(client_options)
  end
end
