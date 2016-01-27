class Posgra::Driver
  include Posgra::Logger::Helper

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
  end

  def describe_users
    rs = @client.exec('SELECT * FROM pg_user')

    options_by_user = {}

    rs.each do |row|
      user = row.fetch('usename')
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


      parse_aclitems(relacl, usename).each do |aclitem|
        role = aclitem.fetch('grantee')
        privs = aclitem.fetch('privileges')

        grants_by_role[role] ||= {}
        grants_by_role[role][nspname] ||= {}
        grants_by_role[role][nspname][relname] = privs
      end
    end

    grants_by_role
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
    privilege_type_grantables = []

    privileges.scan(/([a-z])(\*)?/i).each do |privilege_type_char,is_grantable|
      privilege_type = PRIVILEGE_TYPES[privilege_type_char]

      unless privilege_type
        log(:warn, "unknown privilege type: #{privilege_type_char}", :color => :yellow)
        next
      end

      privilege_type_grantables << {
        'privilege_type' => privilege_type,
        'is_grantable' => !!is_grantable,
      }
    end

    privilege_type_grantables
  end
end
