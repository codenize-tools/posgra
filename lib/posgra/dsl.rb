class Posgra::DSL
  def self.convert_roles(exported, options = {})
    Posgra::DSL::Converter.convert_roles(exported, options)
  end

  def self.convert_grants(exported, options = {})
    Posgra::DSL::Converter.convert_grants(exported, options)
  end

  def self.convert_databases(exported, options = {})
    Posgra::DSL::Converter.convert_databases(exported, options)
  end

  def self.parse_roles(dsl, path, options = {})
    Posgra::DSL::Roles.eval(dsl, path, options).result
  end

  def self.parse_grants(dsl, path, options = {})
    Posgra::DSL::Grants.eval(dsl, path, options).result
  end

  def self.parse_databases(dsl, path, options = {})
    Posgra::DSL::Database.eval(dsl, path, options).result
  end
end
