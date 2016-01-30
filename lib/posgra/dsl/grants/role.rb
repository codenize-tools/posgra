class Posgra::DSL::Grants::Role
  include Posgra::Logger::Helper
  include Posgra::TemplateHelper
  include Posgra::Utils::Helper

  attr_reader :result

  def initialize(context, role, options, &block)
    @role = role
    @options = options
    @context = context.merge(:role => role)
    @result = {}
    instance_eval(&block)
  end

  def schema(name, &block)
    name = name.to_s

    if matched?(name, @options[:include_schema], @options[:exclude_schema])
      @result[name] = Posgra::DSL::Grants::Role::Schema.new(@context, name, @options, &block).result
    end
  end
end
