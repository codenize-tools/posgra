class Posgra::DSL::Roles::Group
  include Posgra::Logger::Helper
  include Posgra::TemplateHelper
  include Posgra::Utils::Helper

  attr_reader :result

  def initialize(context, group, options, &block)
    @group = group
    @options = options
    @context = context.merge(:group => group)
    @result = []
    instance_eval(&block) if block
  end

  def user(name)
    name = name.to_s
    @result << name
  end
end
