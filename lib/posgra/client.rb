class Posgra::Client
  include Posgra::Utils::Helper

  DEFAULT_EXCLUDE_SCHEMA = /\A(?:pg_.*|information_schema)\z/
  DEFAULT_EXCLUDE_ROLE = /\A\z/
  DEFAULT_EXCLUDE_DATABASE = /\A(?:template\d+|postgres)\z/

  def initialize(options = {})
    if options[:exclude_schema]
      options[:exclude_schema] = Regexp.union(
        options[:exclude_schema],
        DEFAULT_EXCLUDE_SCHEMA
      )
    else
      options[:exclude_schema] = DEFAULT_EXCLUDE_SCHEMA
    end

    if options[:exclude_role]
      options[:exclude_role] = Regexp.union(
        options[:exclude_role],
        DEFAULT_EXCLUDE_ROLE
      )
    else
      options[:exclude_role] = DEFAULT_EXCLUDE_ROLE
    end

    if options[:exclude_database]
      options[:exclude_database] = Regexp.union(
        options[:exclude_database],
        DEFAULT_EXCLUDE_DATABASE
      )
    else
      options[:exclude_database] = DEFAULT_EXCLUDE_DATABASE
    end

    @options = options
    @client = connect(options)
    @driver = Posgra::Driver.new(@client, options)
  end

  def export_roles(options = {})
    options = @options.merge(options)
    exported = Posgra::Exporter.export_roles(@driver, options)
    Posgra::DSL.convert_roles(exported, options)
  end

  def export_grants(options = {})
    options = @options.merge(options)
    exported = Posgra::Exporter.export_grants(@driver, options)

    if options[:split]
      dsl_h = Hash.new {|hash, key| hash[key] = {} }

      exported.each do |role, schemas|
        dsl = Posgra::DSL.convert_grants({role => schemas}, options)
        dsl_h[role] = dsl
      end

      dsl_h
    else
      Posgra::DSL.convert_grants(exported, options)
    end
  end

  def export_databases(options = {})
    options = @options.merge(options)
    exported = Posgra::Exporter.export_databases(@driver, options)

    if options[:split]
      dsl_h = Hash.new {|hash, key| hash[key] = {} }

      exported.each do |role, databases|
        dsl = Posgra::DSL.convert_databases({role => databases}, options)
        dsl_h[role] = dsl
      end

      dsl_h
    else
      Posgra::DSL.convert_databases(exported, options)
    end
  end

  def apply_roles(file, options = {})
    options = @options.merge(options)
    walk_for_roles(file, options)
  end

  def apply_grants(file, options = {})
    options = @options.merge(options)
    walk_for_grants(file, options)
  end

  def apply_databases(file, options = {})
    options = @options.merge(options)
    walk_for_database_grants(file, options)
  end

  def close
    @client.close
  end

  private

  def walk_for_roles(file, options)
    expected = load_file(file, :parse_roles, options)
    actual = Posgra::Exporter.export_roles(@driver, options)

    expected_users_by_group = expected.fetch(:users_by_group)
    actual_users_by_group = actual.fetch(:users_by_group)
    expected_users = (expected_users_by_group.values.flatten + expected.fetch(:users)).uniq
    actual_users = (actual_users_by_group.values.flatten + actual.fetch(:users)).uniq

    updated = pre_walk_groups(expected_users_by_group, actual_users_by_group)
    updated = walk_users(expected_users, actual_users) || updated
    walk_groups(expected_users_by_group, actual_users_by_group, expected_users) || updated
  end

  def walk_for_grants(file, options)
    expected = load_file(file, :parse_grants, options)
    actual = Posgra::Exporter.export_grants(@driver, options)
    walk_roles(expected, actual)
  end

  def walk_for_database_grants(file, options)
    expected = load_file(file, :parse_databases, options)
    actual = Posgra::Exporter.export_databases(@driver, options)
    walk_database_roles(expected, actual)
  end

  def walk_users(expected, actual)
    updated = false

    (expected - actual).each do |user|
      updated = @driver.create_user(user) || updated
    end

    (actual - expected).each do |user|
      updated = @driver.drop_user(user) || updated
    end

    updated
  end

  def pre_walk_groups(expected, actual)
    updated = false

    actual.reject {|group, _|
      expected.has_key?(group)
    }.each {|group, actual_users|
      if matched?(group, @options[:include_role], @options[:exclude_role])
        updated = @driver.drop_group(group) || updated
      else
        actual_users.each do |user|
          updated = @driver.drop_user_from_group(user, group) || updated
        end
      end
    }

    updated
  end

  def walk_groups(expected, actual, current_users)
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
        if current_users.include?(user)
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

    expected.keys.each do |expected_object|
      if expected_object.is_a?(Regexp)
        expected_grants = expected.delete(expected_object)

        @driver.describe_objects(schema).each do |object|
          if object =~ expected_object
            expected[object] = expected_grants.dup
          end
        end
      end
    end

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

  def walk_database_roles(expected, actual)
    updated = false

    expected.each do |expected_role, expected_databases|
      actual_databases = actual.delete(expected_role) || {}
      updated = walk_databases(expected_databases, actual_databases, expected_role) || updated
    end

    actual.each do |actual_role, actual_databases|
      actual_databases.each do |database, _|
        updated = @driver.revoke_all_on_database(actual_role, database) || updated
      end
    end

    updated
  end

  def walk_databases(expected, actual, role)
    updated = false

    expected.each do |expected_database, expected_grants|
      actual_grants = actual.delete(expected_database) || {}
      updated = walk_database_grants(expected_grants, actual_grants, role, expected_database) || updated
    end

    actual.each do |actual_database, _|
      updated = @driver.revoke_all_on_database(role, actual_database) || updated
    end

    updated
  end

  def walk_database_grants(expected, actual, role, database)
    updated = false

    expected.each do |expected_priv, expected_options|
      actual_options = actual.delete(expected_priv)

      if actual_options
        if expected_options != actual_options
          updated = @driver.update_database_grant_options(role, expected_priv, expected_options, database) || updated
        end
      else
        updated = @driver.database_grant(role, expected_priv, expected_options, database) || updated
      end
    end

    actual.each do |actual_priv, _|
      updated = @driver.database_revoke(role, actual_priv, database) || updated
    end

    updated
  end

  def load_file(file, method, options)
    if file.kind_of?(String)
      open(file) do |f|
        Posgra::DSL.send(method, f.read, file, options)
      end
    elsif file.respond_to?(:read)
      Posgra::DSL.send(method, file.read, file.path, options)
    else
      raise TypeError, "can't convert #{file} into File"
    end
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
