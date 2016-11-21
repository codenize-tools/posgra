class Posgra::Driver
  include Posgra::Logger::Helper
  include Posgra::Utils::Helper

  DEFAULT_ACL_PRIVS = ENV['POSGRA_DEFAULT_ACL_PRIVS'] || 'arwdDxt'
  DEFAULT_ACL = "{%s=#{DEFAULT_ACL_PRIVS}/%s}"

  DEFAULT_DATABASE_ACL = "{%s=CTc/%s}"

  DEFAULT_ACL_BY_KIND = {
    'S' => '{%s=rwU/%s}'
  }

  PRIVILEGE_TYPES = {
    'a' => 'INSERT',
    'r' => 'SELECT',
    'w' => 'UPDATE',
    'd' => 'DELETE',
    'D' => 'TRUNCATE',
    'x' => 'REFERENCES',
    't' => 'TRIGGER',
    'U' => 'USAGE',
    'R' => 'RULE',
    'X' => 'EXECUTE',
    'C' => 'CREATE',
    'c' => 'CONNECT',
    'T' => 'TEMPORARY',
  }

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

  def revoke_all_on_database(role, database)
    sql = "REVOKE ALL ON DATABASE #{@client.escape_identifier(database)} FROM #{@client.escape_identifier(role)}"
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
      updated = revoke_grant_option(role, priv, schema, object)
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

  def revoke_grant_option(role, priv, schema, object)
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

  def database_grant(role, priv, options, database)
    updated = false

    sql = "GRANT #{priv} ON DATABASE #{@client.escape_identifier(database)} TO #{@client.escape_identifier(role)}"

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

  def update_database_grant_options(role, priv, options, database)
    updated = false

    if options.fetch('is_grantable')
      updated = grant_database_grant_option(role, priv, database)
    else
      updated = revoke_database_grant_option(role, priv, database)
    end

    updated
  end

  def grant_database_grant_option(role, priv, database)
    updated = false

    sql = "GRANT #{priv} ON DATABASE #{@client.escape_identifier(database)} TO #{@client.escape_identifier(role)} WITH GRANT OPTION"
    log(:info, sql, :color => :green)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def revoke_database_grant_option(role, priv, database)
    updated = false

    sql = "REVOKE GRANT OPTION FOR #{priv} ON DATABASE #{@client.escape_identifier(database)} FROM #{@client.escape_identifier(role)}"
    log(:info, sql, :color => :green)

    unless @options[:dry_run]
      exec(sql)
      updated = true
    end

    updated
  end

  def database_revoke(role, priv, database)
    updated = false

    sql = "REVOKE #{priv} ON DATABASE #{@client.escape_identifier(database)} FROM #{@client.escape_identifier(role)}"
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
        pg_class.relname,
        pg_namespace.nspname,
        pg_class.relacl,
        pg_user.usename,
        pg_class.relkind
      FROM
        pg_class
        INNER JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
        INNER JOIN pg_user ON pg_class.relowner = pg_user.usesysid
      WHERE
        pg_class.relkind NOT IN ('i')
    SQL

    grants_by_role = {}

    rs.each do |row|
      relname = row.fetch('relname')
      nspname = row.fetch('nspname')
      relacl = row.fetch('relacl')
      usename = row.fetch('usename')
      relkind = row.fetch('relkind')

      next unless matched?(relname, @options[:include_object], @options[:exclude_object])
      next unless matched?(nspname, @options[:include_schema], @options[:exclude_schema])

      parse_aclitems(relacl, usename, relkind).each do |aclitem|
        role = aclitem.fetch('grantee')
        privs = aclitem.fetch('privileges')
        next unless matched?(role, @options[:include_role], @options[:exclude_role])
        grants_by_role[role] ||= {}
        grants_by_role[role][nspname] ||= {}
        grants_by_role[role][nspname][relname] = privs
      end
    end

    grants_by_role
  end

  def describe_databases
    rs = exec <<-SQL
      SELECT
        pg_database.datname,
        pg_database.datacl,
        pg_user.usename
      FROM
        pg_database
        INNER JOIN pg_user ON pg_database.datdba = pg_user.usesysid
    SQL

    database_grants_by_role = {}

    rs.each do |row|
      datname = row.fetch('datname')
      datacl = row.fetch('datacl')
      usename = row.fetch('usename')

      next unless matched?(datname, @options[:include_database], @options[:exclude_database])

      parse_database_aclitems(datacl, usename).each do |aclitem|
        role = aclitem.fetch('grantee')
        privs = aclitem.fetch('privileges')
        next unless matched?(role, @options[:include_role], @options[:exclude_role])
        database_grants_by_role[role] ||= {}
        database_grants_by_role[role][datname] = privs
      end
    end

    database_grants_by_role
  end

  private

  def parse_aclitems(aclitems, owner, relkind)
    aclitems_fmt = DEFAULT_ACL_BY_KIND.fetch(relkind, DEFAULT_ACL)
    aclitems ||= aclitems_fmt % [owner, owner]
    parse_aclitems0(aclitems)
  end

  def parse_database_aclitems(aclitems, owner)
    aclitems ||= DEFAULT_DATABASE_ACL % [owner, owner]
    parse_aclitems0(aclitems)
  end

  def parse_aclitems0(aclitems)
    aclitems = aclitems[1..-2].split(',')

    aclitems.map do |aclitem|
      aclitem = unquote_aclitem(aclitem)
      grantee, privileges_grantor = aclitem.split('=', 2)
      privileges, grantor = privileges_grantor.split('/', 2)
      grantee = unescape_aclname(grantee)
      grantor = unescape_aclname(grantor)

      {
        'grantee' => grantee,
        'privileges' => expand_privileges(privileges),
        'grantor' => grantor,
      }
    end
  end

  def expand_privileges(privileges)
    options_by_privilege = {}

    privileges.scan(/([a-z])(\*)?/i).each do |privilege_type_char,is_grantable|
      privilege_type = PRIVILEGE_TYPES[privilege_type_char]

      unless privilege_type
        log(:warn, "Unknown privilege type: #{privilege_type_char}", :color => :yellow)
        next
      end

      options_by_privilege[privilege_type] = {
        'is_grantable' => !!is_grantable,
      }
    end

    options_by_privilege
  end

  def exec(sql)
    log(:debug, sql)
    @client.exec(sql)
  end

  def unquote_aclitem(str)
    str.sub(/\A"/, '').sub(/"\z/, '').gsub('\\', '')
  end

  def unescape_aclname(str)
    # Fix for Redshift: "group "
    str.sub(/\A"/, '').sub(/"\z/, '').gsub('""', '"').sub(/\Agroup /, '')
  end
end
