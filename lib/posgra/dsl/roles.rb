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
    group_users = @result[:users_by_group].flat_map do |group, users|
      if users.empty?
        [group, nil]
      else
        users.map {|u| [group, u] }
      end
    end

    new_users_by_group = {}

    group_users.each do |group, user|
      next unless [group, user].any? {|i| not i.nil? and matched?(i, @options[:include_role], @options[:exclude_role]) }
      new_users_by_group[group] ||= []
      new_users_by_group[group] << user if user
    end

    new_users_by_group.values.each(&:uniq!)
    @result[:users_by_group] = new_users_by_group

    @result
  end

  def initialize(path, options = {}, &block)
    @path = path
    @options = options
    @result = {
      :users => {},
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

  def user(name, options = {}, &block)
    name = name.to_s

    if matched?(name, @options[:include_role], @options[:exclude_role])
      @result[:users][name] = options
    end
  end

  def group(name, &block)
    name = name.to_s
    @result[:users_by_group][name] = Posgra::DSL::Roles::Group.new(@context, name, @options, &block).result
  end
end
