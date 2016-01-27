class Posgra::DSL::Context::Role::Schema::On
  include Posgra::Logger::Helper
  include Posgra::TemplateHelper

  attr_reader :result

  def initialize(context, object, options, &block)
    @object = object
    @options = options
    @context = context.merge(:object => object)
    @result = {}
    instance_eval(&block)
  end

  def grant(name, options = {})
    @result[name] = {
      'is_grantable' => !!options[:grantable]
    }
  end
end
