class Posgra::Client
  def initialize(options = {})
    options = {
      :exclude_schema => /\A(?:pg_.*|information_schema)\z/,
      :exclude_role => /\A\z/,
      #:identifier => ...
    }.merge(options)

    @options = options
    client = connect(options)
    @driver = Posgra::Driver.new(client, options)
  end

  def export(options = {})
    options = @options.merge(options)
    exported = Posgra::Exporter.export(@driver, options)

    if options[:split]
      dsl_h = Hash.new {|hash, key| hash[key] = {} }

      exported.each do |export_type, export_values|
        export_values.each do |item|
          if export_values.is_a?(Hash)
            key, value = item
            item = {key => value}
          else
            item = [item]
          end

          dsl = Posgra::DSL.convert({export_type => item}, options)
          dsl_h[export_type][key] = dsl
        end
      end

      dsl_h
    else
      Posgra::DSL.convert(exported, options)
    end
  end

  def apply(file, options = {})
    options = @options.merge(options)
    walk(file, options)
  end

  private

  def walk(file, options)
    expected = load_file(file, options)
    expected[:users] = expected_users(expected[:users_by_group], expected[:grants_by_role])
    actual = Posgra::Exporter.export(@driver, options)

    updated = walk_users(expected.fetch(:users), actual.fetch(:users))
    updated = walk_groups(expected.fetch(:users_by_group), actual.fetch(:users_by_group)) || updated
    walk_roles(expected.fetch(:grants_by_role), actual.fetch(:grants_by_role)) || updated
  end

  def walk_users(expected, actual)
    (expected - actual).each do |user|
      # TODO: create user
    end

    (actual - expected).each do |user|
      # TODO: drop user
    end
  end

  def walk_groups(expected, actual)
    expected.each do |expected_group, expected_users|
      actual_users = actual.delete(expected_group)

      unless actual_users
        # TODO: create group
        actual_users = []
      end

      # TODO: update group
    end

    actual.each do |actual_group, actual_users|
      # TODO: drop group
    end
  end

  def walk_roles(expected, actual)
    # TODO:
  end

  def load_file(file, options)
    # TODO: パーサにフィルタを追加する
    if file.kind_of?(String)
      open(file) do |f|
        Posgra::DSL.parse(f.read, file, options)
      end
    elsif file.respond_to?(:read)
      Posgra::DSL.parse(file.read, file.path, options)
    else
      raise TypeError, "can't convert #{file} into File"
    end
  end

  def expected_users(users_by_group, grants_by_role)
    groups = users_by_group.keys
    users = users_by_group.values.flatten
    roles_without_group = grants_by_role.keys - groups
    (users + roles_without_group).uniq
  end

  def connect(options)
    connect_options = {}

    PG::Connection::CONNECT_ARGUMENT_ORDER.each do |key|
      value = options[key] || options[key.to_sym]

      if value
        connect_options[key] = value
      end
    end

    PGconn.connect(connect_options)
  end
end
