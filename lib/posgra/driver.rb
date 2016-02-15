class Posgra::Driver
  include Posgra::Logger::Helper
  include Posgra::Utils::Helper

  def initialize(client, options = {})
    unless client.type_map_for_results.is_a?(PG::TypeMapAllStrings)
      raise 'PG::Connection#type_map_for_results must be PG::TypeMapAllStrings'
    end

    @client = client
    @options = options
    @identifier = options.fetch(:identifier)
  end

  def create_user(user)
    updated = false

    password =  @identifier.identify(user)
    sql = "CREATE USER #{@client.escape_identifier(user)} PASSWORD #{@client.escape_literal(password)}"
    log(:info, sql, :color => :cyan)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def drop_user(user)
    updated = false

    sql = "DROP USER #{@client.escape_identifier(user)}"
    log(:info, sql, :color => :red)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def create_group(group)
    updated = false

    sql = "CREATE GROUP #{@client.escape_identifier(group)}"
    log(:info, sql, :color => :cyan)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def add_user_to_group(user, group)
    updated = false

    sql = "ALTER GROUP #{@client.escape_identifier(group)} ADD USER #{@client.escape_identifier(user)}"
    log(:info, sql, :color => :green)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def drop_user_from_group(user, group)
    updated = false

    sql = "ALTER GROUP #{@client.escape_identifier(group)} DROP USER #{@client.escape_identifier(user)}"
    log(:info, sql, :color => :cyan)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def drop_group(group)
    updated = false

    sql = "DROP GROUP #{@client.escape_identifier(group)}"
    log(:info, sql, :color => :red)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def revoke_all_on_schema(role, schema)
    updated = false

    describe_objects(schema).each do |object|
      updated = revoke_all_on_object(role, schema, object) || updated
    end

    updated
  end

  def revoke_all_on_object(role, schema, object)
    updated = false

    sql = "REVOKE ALL ON #{@client.escape_identifier(schema)}.#{@client.escape_identifier(object)} FROM #{@client.escape_identifier(role)}"
    log(:info, sql, :color => :green)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def grant(role, priv, options, schema, object)
    updated = false

    sql = "GRANT #{priv} ON #{@client.escape_identifier(schema)}.#{@client.escape_identifier(object)} TO #{@client.escape_identifier(role)}"

    if options['is_grantable']
      sql << ' WITH GRANT OPTION'
    end

    log(:info, sql, :color => :green)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def update_grant_options(role, priv, options, schema, object)
    updated = false

    if options.fetch('is_grantable')
      updated = grant_grant_option(role, priv, schema, object)
    else
      updated = roveke_grant_option(role, priv, schema, object)
    end

    updated
  end

  def grant_grant_option(role, priv, schema, object)
    updated = false

    sql = "GRANT #{priv} ON #{@client.escape_identifier(schema)}.#{@client.escape_identifier(object)} TO #{@client.escape_identifier(role)} WITH GRANT OPTION"
    log(:info, sql, :color => :green)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def roveke_grant_option(role, priv, schema, object)
    updated = false

    sql = "REVOKE GRANT OPTION FOR #{priv} ON #{@client.escape_identifier(schema)}.#{@client.escape_identifier(object)} FROM #{@client.escape_identifier(role)}"
    log(:info, sql, :color => :green)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def revoke(role, priv, schema, object)
    updated = false

    sql = "REVOKE #{priv} ON #{@client.escape_identifier(schema)}.#{@client.escape_identifier(object)} FROM #{@client.escape_identifier(role)}"
    log(:info, sql, :color => :green)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def describe_objects(schema)
    rs = exec <<-SQL
      SELECT
        pg_class.relname,
        pg_namespace.nspname
      FROM
        pg_class
        INNER JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
      WHERE
        pg_namespace.nspname = #{@client.escape_literal(schema)}
        AND pg_class.relkind NOT IN ('i')
    SQL

    objects = []

    rs.each do |row|
      relname = row.fetch('relname')
      next unless matched?(relname, @options[:include_object], @options[:exclude_object])
      objects << relname
    end

    objects
  end

  def describe_users
    rs = exec('SELECT * FROM pg_user')

    options_by_user = {}

    rs.each do |row|
      user = row.fetch('usename')
      next unless matched?(user, @options[:include_role], @options[:exclude_role])
      options_by_user[user] = row.select {|_, v| v == 't' }.keys
    end

    options_by_user
  end

  def describe_groups
    rs = exec <<-SQL
      SELECT
        pg_group.groname,
        pg_user.usename
      FROM
        pg_group
        LEFT JOIN pg_user ON pg_user.usesysid = ANY(pg_group.grolist)
    SQL

    users_by_group = {}

    rs.each do |row|
      group = row.fetch('groname')
      user = row.fetch('usename')
      next unless [group, user].any? {|i| not i.nil? and matched?(i, @options[:include_role], @options[:exclude_role]) }
      users_by_group[group] ||= []
      users_by_group[group] << user if user
    end

    users_by_group
  end

  def describe_grants
    rs = exec <<-SQL
      SELECT
        c.relname,
        n.nspname,
        r.rolname,
        c.privilege_type,
        c.is_grantable
      FROM (
        SELECT
          *,
          (aclexplode(coalesce(relacl, acldefault(CASE relkind WHEN 'v' THEN 'r' ELSE relkind END, relowner)))).*
        FROM
          pg_class
        WHERE
          relkind NOT IN ('i')
      ) c
      INNER JOIN pg_namespace n ON n.oid = c.relnamespace
      INNER JOIN pg_roles r ON r.oid = c.grantee
    SQL

    grants_by_role = {}
    rs.each do |row|
      relname = row.fetch('relname')
      nspname = row.fetch('nspname')
      rolname = row.fetch('rolname')
      privilege_type = row.fetch('privilege_type')
      is_grantable = row.fetch('is_grantable')

      next unless matched?(relname, @options[:include_object], @options[:exclude_object])
      next unless matched?(nspname, @options[:include_schema], @options[:exclude_schema])

      next unless matched?(rolname, @options[:include_role], @options[:exclude_role])
      grants_by_role[rolname] ||= {}
      grants_by_role[rolname][nspname] ||= {}
      grants_by_role[rolname][nspname][relname] ||= {}
      grants_by_role[rolname][nspname][relname][privilege_type] ||= {}
      grants_by_role[rolname][nspname][relname][privilege_type]['is_grantable'] = is_grantable == 't'
    end

    grants_by_role
  end

  private

  def exec(sql)
    log(:debug, sql)
    @client.exec(sql)
  end
end
