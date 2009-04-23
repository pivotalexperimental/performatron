class Performatron::Configuration
  include Singleton

  def initialize
    app_filename = File.join(RAILS_ROOT, "config", "performatron.yml")
    app_config = File.exist?(app_filename) ? YAML.load(ERB.new(File.read(app_filename)).result) : {} 
    @config = app_config[ENV['SETUP'] || 'default']
  end

  def [](key)
    @config[key.to_s]
  end
end