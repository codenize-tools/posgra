class Posgra::Driver

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

    rs.to_a
  end
end
