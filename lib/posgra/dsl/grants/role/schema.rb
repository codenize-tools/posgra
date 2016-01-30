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

  def on(name, &block)
    @result[name] = Posgra::DSL::Grants::Role::Schema::On.new(@context, name, @options, &block).result
  end
end
