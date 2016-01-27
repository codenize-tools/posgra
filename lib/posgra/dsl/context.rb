class Posgra::DSL::Context
  include Posgra::Logger::Helper
  include Posgra::TemplateHelper

  def self.eval(dsl, path, options = {})
    self.new(path, options) do
      eval(dsl, binding, path)
    end
  end

  attr_reader :result

  def initialize(path, options = {}, &block)
    @path = path
    @options = options
    @result = {}

    @context = Hashie::Mash.new(
      :path => path,
      :options => options,
      :templates => {},
    )

    instance_eval(&block)
  end

  private

  def template(name, &block)
    @context.templates[name.to_s] = block
  end

  def require(file)
    pgrantfile = (file =~ %r|\A/|) ? file : File.expand_path(File.join(File.dirname(@path), file))

    if File.exist?(pgrantfile)
      instance_eval(File.read(pgrantfile), pgrantfile)
    elsif File.exist?(pgrantfile + '.rb')
      instance_eval(File.read(pgrantfile + '.rb'), pgrantfile + '.rb')
    else
      Kernel.require(file)
    end
  end

  def group(name, &block)
    @result[:user_by_group] = Posgra::DSL::Context::Group.new(@context, name, @options, &block).result
  end

  def role(name)
  end
end
