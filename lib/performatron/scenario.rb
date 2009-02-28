class Performatron::Scenario
  cattr_accessor :loaded_scenarios
  cattr_accessor :verbose
  self.loaded_scenarios = {}
  self.verbose = true

  attr_reader :name
  attr_reader :proc
  attr_reader :data_store
  def initialize(name, options = {}, &block)
    @name = name.to_s
    @proc = block
    @data_store = {}
    self.class.loaded_scenarios[self.name] = self
  end

  def build
    self.proc.call(self)
  end

  def sanitized_name
    name.gsub(/\W+/, "_")
  end

  def [](key)
    @data_store[key.to_s]
  end

  def []=(key, value)
    @data_store[key.to_s] = value
  end

  def self.build_all(environment = RAILS_ENV)
    loaded_scenarios.values.each do |scenario|
      log("Building scenario #{scenario.name}")
      log("  clearing database")
      clear_database(environment)
      log("  building data")
      scenario.build
      log("  dumping datastore")
      scenario.dump_data_store
      log("  dumping database")
      dump_database(scenario.sanitized_name)
      log("  done")
    end
  end

  def self.load_all_datastores(directory = "/tmp/scenarios")
    loaded_scenarios.values.each do |scenario|
      scenario.load_data_store(directory)
    end
  end

  def dump_data_store(directory = "/tmp/scenarios")
    file = directory + "/" + sanitized_name + ".yml"
    FileUtils.mkdir_p(directory)    
    new_data_store = convert_hash_to_attributes(data_store)
    File.open(file, "w") do |f|
      f.write(new_data_store.to_yaml)
    end
  end

  def load_data_store(directory = "/tmp/scenarios")
    file = directory + "/" + sanitized_name + ".yml"
    @data_store = YAML.load_file(file)
  end

  def self.clear_database(environment = RAILS_ENV)
    ActiveRecord::Schema.verbose = false
    ActiveRecord::Base.connection.recreate_database(ActiveRecord::Base.configurations["test"]["database"], ActiveRecord::Base.configurations["test"])
    ActiveRecord::Base.establish_connection environment
    file = ENV['SCHEMA'] || "#{RAILS_ROOT}/db/schema.rb"
    load(file)
  ensure
    ActiveRecord::Schema.verbose = true
  end

  def self.dump_database(filename = "scenario", directory = "/tmp/scenarios")
    file = directory + "/" + filename + ".sql"
    FileUtils.mkdir_p(directory)
    config = ActiveRecord::Base.configurations["test"]
    database = config["database"]
    hostname = config["host"] || "localhost"
    username = config["username"]
    password_parameter = config["password"] ? "-p#{config["password"]}" : ""
    cmd = "/usr/bin/env mysqldump #{database} -u#{username} #{password_parameter} --default-character-set=utf8 -h #{hostname} > #{file}"
    raise "Unable to dump database using command: #{cmd}" unless system cmd
  end

  def self.load_database(filename = "scenario", environment = RAILS_ENV, directory = "/tmp/scenarios")
    clear_database(environment)
    file = directory + "/" + filename + ".sql"
    FileUtils.mkdir_p(directory)
    config = ActiveRecord::Base.configurations[environment]
    database = config["database"]
    hostname = config["host"] || "localhost"
    username = config["username"]
    password_parameter = config["password"] ? "-p#{config["password"]}" : ""
    cmd = "/usr/bin/env mysql #{database} -u#{username} #{password_parameter} --default-character-set=utf8 -h #{hostname} < #{file}"
    raise "Unable to load database using command: #{cmd}" unless system cmd
  end

  def ==(other)
    self.name == other.name
  end

  private
  def self.log(msg)
    puts "  * #{msg}" if verbose
  end

  def convert_hash_to_attributes(hash)
    new_hash = {}
    hash.each do |k, v|
      new_hash[k] = convert_value_to_attributes(v)
    end
    new_hash
  end

  def convert_value_to_attributes(value)
    case value
    when Array:
      value.collect{|v| convert_value_to_attributes(v)}
    when Hash:
      convert_hash_to_attributes(value)
    else
      value.respond_to?(:attributes) ? value.attributes.except("created_at", "updated_at") : value
    end
  end
end