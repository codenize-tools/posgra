class Posgra::DSL::Grants::Role::Schema
  include Posgra::Logger::Helper
  include Posgra::TemplateHelper

  attr_reader :result

  def initialize(context, schema, options, &block)
    @schema = schema
    @options = options
    @context = context.merge(:schema => schema)
    @result = {}
    instance_eval(&block)
  end

  def on(name, options = {}, &block)
    unless name.is_a?(Regexp)
      name = name.to_s
    end

    if options[:expired]
      expired = Time.parse(options[:expired])

      if Time.new >= expired
        log(:warn, "Privilege for `#{name}` has expired", :color => :yellow)
        return
      end
    end

    @result[name] = Posgra::DSL::Grants::Role::Schema::On.new(@context, name, @options, &block).result
  end
end
