class Posgra::Exporter
  def self.export_roles(driver, options = {})
    self.new(driver, options).export_roles
  end

  def self.export_grants(driver, options = {})
    self.new(driver, options).export_grants
  end

  def self.export_databases(driver, options = {})
    self.new(driver, options).export_databases
  end

  def initialize(driver, options = {})
    @driver = driver
    @options = options
  end

  def export_roles
    {
      :users => @driver.describe_users,
      :users_by_group => @driver.describe_groups,
    }
  end

  def export_grants
    @driver.describe_grants
  end

  def export_databases
    @driver.describe_databases
  end
end
