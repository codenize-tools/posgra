class Posgra::DSL
  def self.convert(exported, options = {})
    Posgra::DSL::Converter.convert(exported, options)
  end

  def self.parse(dsl, path, options = {})
    #Posgra::DSL::Context.eval(dsl, path, options).result
  end
end
