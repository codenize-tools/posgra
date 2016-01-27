class Posgra::DSL::Context::Role::Schema
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

  def on(name)
    # TODO:
  end
end
