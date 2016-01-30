class Posgra::DSL::Converter
  def self.convert_roles(exported, options = {})
    self.new(exported, options).convert_roles
  end

  def self.convert_grants(exported, options = {})
    self.new(exported, options).convert_grants
  end

  def initialize(exported, options = {})
    @exported = exported
    @options = options
  end

  def convert_roles
    users_by_group = @exported[:users_by_group] || {}
    users = @exported.fetch(:users, []) - users_by_group.values.flatten

    [
      output_users(users),
      output_groups(users_by_group),
    ].join("\n").strip
  end

  def convert_grants
    grants_by_role = @exported || {}
    output_roles(grants_by_role)
  end

  private

  def output_users(users)
    users.sort.map {|user|
      "user #{user.inspect}"
    }.join("\n") + "\n"
  end

  def output_groups(users_by_group)
    users_by_group.sort_by {|g, _| g }.map {|group, users|
      output_group(group, users)
    }.join("\n")
  end

  def output_group(group, users)
    if users.empty?
      users = "# no users"
    else
      users = users.sort.map {|user|
        "user #{user.inspect}"
      }.join("\n  ")
    end

    <<-EOS
group #{group.inspect} do
  #{users}
end
    EOS
  end

  def output_roles(grants_by_role)
    grants_by_role.sort_by {|r, _| r }.map {|role, grants_by_schema|
      output_role(role, grants_by_schema)
    }.join("\n")
  end

  def output_role(role, grants_by_schema)
    if grants_by_schema.empty?
      schemas = "# no schemas"
    else
      schemas = output_schemas(grants_by_schema)
    end

    <<-EOS
role #{role.inspect} do
  #{schemas}
end
    EOS
  end

  def output_schemas(grants_by_schema)
    grants_by_schema.sort_by {|s, _| s }.map {|schema, grants_by_object|
      output_schema(schema, grants_by_object).strip
    }.join("\n  ")
  end

  def output_schema(schema, grants_by_object)
    if grants_by_object.empty?
      objects = "# no objects"
    else
      objects = output_objects(grants_by_object)
    end

    <<-EOS
  schema #{schema.inspect} do
    #{objects}
  end
    EOS
  end

  def output_objects(grants_by_object)
    grants_by_object.sort_by {|o, _| o }.map {|object, grants|
      output_object(object, grants).strip
    }.join("\n    ")
  end

  def output_object(object, grants)
    if grants.empty?
      grants = "# no grants"
    else
      grants = output_grants(grants)
    end

    <<-EOS
    on #{object.inspect} do
      #{grants}
    end
    EOS
  end

  def output_grants(grants)
    grants.sort_by {|g| g.to_s }.map {|privilege_type, options|
      output_grant(privilege_type, options).strip
    }.join("\n      ")
  end

  def output_grant(privilege_type, options)
    is_grantable = options.fetch('is_grantable')
    out = "grant #{privilege_type.inspect}"

    if is_grantable
      out << ", :grantable => #{is_grantable}"
    end

    out
  end
end
