class Posgra::DSL::Roles
  include Posgra::Logger::Helper
  include Posgra::TemplateHelper
  include Posgra::Utils::Helper

  def self.eval(dsl, path, options = {})
    self.new(path, options) do
      eval(dsl, binding, path)
    end
  end

  def result
    @result.fetch(:users).uniq
    @result
  end

  def initialize(path, options = {}, &block)
    @path = path
    @options = options
    @result = {
      :users => [],
      :users_by_group => {},
    }

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

  def user(name, &block)
    name = name.to_s

    if matched?(name, @options[:include_role], @options[:exclude_role])
      @result[:users] << name
    end
  end

  def group(name, &block)
    name = name.to_s

    if matched?(name, @options[:include_role], @options[:exclude_role])
      @result[:users_by_group][name] = Posgra::DSL::Roles::Group.new(@context, name, @options, &block).result
    end
  end
end
