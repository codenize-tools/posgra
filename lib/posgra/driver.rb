class Posgra::Driver
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
    @client = client
    @options = options
  end

  def list_users
    # TODO: 型の変換とカラムの絞り込みを検討
    rs = @client.exec('SELECT * FROM pg_user')
    rs.to_a
  end

  def list_groups
    rs = @client.exec <<-SQL
      SELECT
        pg_group.groname,
        pg_user.usename
      FROM
        pg_group
        LEFT JOIN pg_user ON pg_user.usesysid = ANY(pg_group.grolist)
    SQL

    user_by_group = Hash.new {|hash, key| hash[key] = [] }

    rs.each do |row|
      group = row['groname']
      user = row['usename']
      user_by_group[group] << user
    end

    user_by_group
  end

  def list_grants
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

    rs.map do |row|
      relacl = row.delete('relacl')
      usename = row.delete('usename')
      row['relacl'] = parse_aclitem(relacl, usename)
      row
    end
  end

  private

  def parse_aclitem(aclitems, owner)
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
    privileges.scan(/([a-z])(\*)?/i).map {|privilege_type,is_grantable|
      privilege_type = PRIVILEGE_TYPES[privilege_type]
      # TODO: 不明なタイプの場合は警告を出す

      {
        'privilege_type' => privilege_type,
        'is_grantable' => !!is_grantable,
      }
    }.select {|h| h['privilege_type'] }
  end
end
