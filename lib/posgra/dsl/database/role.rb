class Posgra::DSL::Database::Role
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

  def database(name, &block)
    name = name.to_s

    if matched?(name, @options[:include_database], @options[:exclude_database])
      @result[name] = Posgra::DSL::Database::Role::Database.new(@context, name, @options, &block).result
    end
  end
end
