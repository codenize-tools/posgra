class Posgra::DSL::Database::Role::Database
  include Posgra::Logger::Helper
  include Posgra::TemplateHelper

  attr_reader :result

  def initialize(context, database, options, &block)
    @database = database
    @options = options
    @context = context.merge(:database => database)
    @result = {}
    instance_eval(&block)
  end

  def grant(name, options = {})
    name = name.to_s

    @result[name] = {
      'is_grantable' => !!options[:grantable]
    }
  end
end
