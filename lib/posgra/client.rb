class Posgra::Client
  def initialize(options = {})
    options = {
      :exclude_schema => /\A(?:pg_.*|information_schema)\z/,
      :exclude_role => /\A\z/,
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
    expected[:users] = build_expected_users(expected[:users_by_group], expected[:grants_by_role])
    actual = Posgra::Exporter.export(@driver, options)

    expected_users_by_group = expected.fetch(:users_by_group)
    actual_users_by_group = actual.fetch(:users_by_group)
    expected_users = expected.fetch(:users)
    actual_users = actual.fetch(:users)
    expected_grants_by_role = expected.fetch(:grants_by_role)
    actual_grants_by_role = actual.fetch(:grants_by_role)

    updated = pre_walk_groups(expected_users_by_group, actual_users_by_group, actual_grants_by_role)
    updated = walk_users(expected_users, actual_users, actual_grants_by_role) || updated
    updated = walk_groups(expected_users_by_group, actual_users_by_group, expected_users) || updated
    walk_roles(expected_grants_by_role, actual_grants_by_role) || updated
  end

  def walk_users(expected, actual, actual_grants_by_role)
    updated = false

    (expected - actual).each do |user|
      updated = @driver.create_user(user) || updated
    end

    (actual - expected).each do |user|
      updated = @driver.drop_user(user) || updated
      actual_grants_by_role.fetch(user, {}).clear
    end

    updated
  end

  def pre_walk_groups(expected, actual, actual_grants_by_role)
    updated = false

    actual.reject {|group, _|
      expected.has_key?(group)
    }.each {|group, _|
      updated = @driver.drop_group(group) || updated
      actual_grants_by_role.fetch(group, {}).clear
    }

    updated
  end

  def walk_groups(expected, actual, expected_users)
    updated = false

    expected.each do |expected_group, expected_users|
      actual_users = actual.delete(expected_group)

      unless actual_users
        updated = @driver.create_group(expected_group) || updated
        actual_users = []
      end

      (expected_users - actual_users).each do |user|
        updated = @driver.add_user_to_group(user, expected_group) || updated
      end

      (actual_users - expected_users).each do |user|
        if expected_users.include?(user)
          updated = @driver.drop_user_from_group(user, expected_group) || updated
        end
      end
    end

    updated
  end

  def walk_roles(expected, actual)
    updated = false

    expected.each do |expected_role, expected_schemas|
      actual_schemas = actual.delete(expected_role) || {}
      updated = walk_schemas(expected_schemas, actual_schemas, expected_role) || updated
    end

    actual.each do |actual_role, actual_schemas|
      actual_schemas.each do |schema, _|
        updated = @driver.revoke_all_on_schema(actual_role, schema) || updated
      end
    end

    updated
  end

  def walk_schemas(expected, actual, role)
    updated = false

    expected.each do |expected_schema, expected_objects|
      actual_objects = actual.delete(expected_schema) || {}
      updated = walk_objects(expected_objects, actual_objects, role, expected_schema) || updated
    end

    actual.each do |actual_schema, _|
      updated = @driver.revoke_all_on_schema(role, actual_schema) || updated
    end

    updated
  end

  def walk_objects(expected, actual, role, schema)
    updated = false

    expected.each do |expected_object, expected_grants|
      actual_grants = actual.delete(expected_object) || {}
      updated = walk_grants(expected_grants, actual_grants, role, schema, expected_object) || updated
    end

    actual.each do |actual_object, _|
      updated = @driver.revoke_all_on_object(role, schema, actual_object) || updated
    end

    updated
  end

  def walk_grants(expected, actual, role, schema, object)
    updated = false

    expected.each do |expected_priv, expected_options|
      actual_options = actual.delete(expected_priv)

      if actual_options
        if expected_options != actual_options
          updated = @driver.update_grant_options(role, expected_priv, expected_options, schema, object) || updated
        end
      else
        updated = @driver.grant(role, expected_priv, expected_options, schema, object) || updated
      end
    end

    actual.each do |actual_priv, _|
      updated = @driver.revoke(role, actual_priv, schema, object) || updated
    end

    updated
  end

  def load_file(file, options)
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

  def build_expected_users(users_by_group, grants_by_role)
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
