class Posgra::Driver
  include Posgra::Logger::Helper
  include Posgra::Utils::Helper

  DEFAULT_ACL = '{%s=arwdDxt/%s}'

  PRIVILEGE_TYPES = {
    'a' => 'INSERT',
    'r' => 'SELECT',
    'w' => 'UPDATE',
    'd' => 'DELETE',
    'D' => 'TRUNCATE',
    'x' => 'REFERENCES',
    't' => 'TRIGGER',
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
      @client.query(sql)
      updated = true
    end

    updated
  end

  def drop_user(user)
    updated = false

    sql = "DROP USER #{@client.escape_identifier(user)}"
    log(:info, sql, :color => :red)

    unless @options[:dry_run]
      @client.query(sql)
      updated = true
    end

    updated
  end

  def create_group(group)
    updated = false

    sql = "CREATE GROUP #{@client.escape_identifier(group)}"
    log(:info, sql, :color => :cyan)

    unless @options[:dry_run]
      @client.query(sql)
      updated = true
    end

    updated
  end

  def add_user_to_group(user, group)
    updated = false

    sql = "ALTER GROUP #{@client.escape_identifier(group)} ADD USER #{@client.escape_identifier(user)}"
    log(:info, sql, :color => :green)

    unless @options[:dry_run]
      @client.query(sql)
      updated = true
    end

    updated
  end

  def drop_user_from_group(user, group)
    updated = false

    sql = "ALTER GROUP #{@client.escape_identifier(group)} DROP USER #{@client.escape_identifier(user)}"
    log(:info, sql, :color => :cyan)

    unless @options[:dry_run]
      @client.query(sql)
      updated = true
    end

    updated
  end

  def drop_group(group)
    updated = false

    sql = "DROP GROUP #{@client.escape_identifier(group)}"
    log(:info, sql, :color => :red)

    unless @options[:dry_run]
      revoke_all(group)
      @client.query(sql)
      updated = true
    end

    updated
  end

  def revoke_all(role)
    describe_schemas.each do |schema|
      sql = "REVOKE ALL ON ALL TABLES IN SCHEMA #{@client.escape_identifier(schema)} FROM #{@client.escape_identifier(role)}"
      log(:debug, sql, :color => :green)

      unless @options[:dry_run]
        @client.query(sql)
      end
    end
  end

  def describe_users
    rs = @client.exec('SELECT * FROM pg_user')

    options_by_user = {}

    rs.each do |row|
      user = row.fetch('usename')
      next unless matched?(user, @options[:include_role], @options[:exclude_role])
      options_by_user[user] = row.select {|_, v| v == 't' }.keys
    end

    options_by_user
  end

  def describe_groups
    rs = @client.exec <<-SQL
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
      next unless [group, user].any? {|i| matched?(i, @options[:include_role], @options[:exclude_role]) }
      users_by_group[group] ||= []
      users_by_group[group] << user if user
    end

    users_by_group
  end

  def describe_grants
    rs = @client.exec <<-SQL
      SELECT
        pg_class.relname,
        pg_namespace.nspname,
        pg_class.relacl,
        pg_user.usename
      FROM
        pg_class
        INNER JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
        INNER JOIN pg_user ON pg_class.relowner = pg_user.usesysid
    SQL

    grants_by_role = {}

    rs.each do |row|
      relname = row.fetch('relname')
      nspname = row.fetch('nspname')
      relacl = row.fetch('relacl')
      usename = row.fetch('usename')

      next unless matched?(nspname, @options[:include_schema], @options[:exclude_schema])

      parse_aclitems(relacl, usename).each do |aclitem|
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

  def describe_schemas
    rs = @client.exec <<-SQL
      SELECT
        nspname
      FROM
        pg_namespace
    SQL

    rs.map do |row|
      row.fetch('nspname')
    end
  end

  private

  def parse_aclitems(aclitems, owner)
    aclitems ||= DEFAULT_ACL % [owner, owner]
    aclitems = aclitems[1..-2].split(',')

    aclitems.map do |aclitem|
      grantee, privileges_grantor = aclitem.split('=', 2)
      privileges, grantor = privileges_grantor.split('/', 2)

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
        log(:warn, "unknown privilege type: #{privilege_type_char}", :color => :yellow)
        next
      end

      options_by_privilege[privilege_type] = {
        'is_grantable' => !!is_grantable,
      }
    end

    options_by_privilege
  end
end
