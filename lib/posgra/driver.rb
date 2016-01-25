class Posgra::Driver
  DEFAULT_ACL = '{%s=arwdDxt/%s}'

  def initialize(client, options = {})
    @client = client
    @options = options
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
      grantee, privilege_types_grantor = aclitem.split('=', 2)
      privilege_types, grantor = privilege_types_grantor.split('/', 2)

      {
        :grantee => grantee,
        :privilege_types => privilege_types,
        :grantor => grantor,
      }
    end
  end
end
