class Posgra::DSL::Context::Group
  include Posgra::Logger::Helper
  include Posgra::TemplateHelper

  attr_reader :result

  def initialize(context, group, options, &block)
    @group = group
    @options = options
    @context = context.merge(:group => group)
    @result = []
    instance_eval(&block)
  end

  def user(name)
    name = name.kind_of?(Regexp) ? name : name.to_s
    @result << name
  end
end
