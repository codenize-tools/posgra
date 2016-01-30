class Posgra::Exporter
  def self.export_roles(driver, options = {}, &block)
    self.new(driver, options).export_roles(&block)
  end

  def self.export_grants(driver, options = {}, &block)
    self.new(driver, options).export_grants(&block)
  end

  def initialize(driver, options = {})
    @driver = driver
    @options = options
  end

  def export_roles
    {
      :users => @driver.describe_users.keys,
      :users_by_group => @driver.describe_groups,
    }
  end

  def export_grants
    @driver.describe_grants
  end
end
