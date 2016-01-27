class Posgra::Exporter
  def self.export(driver, options = {}, &block)
    self.new(driver, options).export(&block)
  end

  def initialize(driver, options = {})
    @driver = driver
    @options = options
  end

  def export
    {
      :users => @driver.describe_users.keys,
      :users_by_group => @driver.describe_groups,
      :grants_by_role => @driver.describe_grants,
    }
  end
end
