class Performatron::Scenario
  cattr_accessor :loaded_scenarios
  cattr_accessor :verbose
  self.loaded_scenarios = {}
  self.verbose = true

  attr_reader :name
  attr_reader :proc
  attr_reader :data_store
  attr_reader :base_sql_dump
  
  def initialize(name, options = {}, &block)
    options.symbolize_keys!
    @name = name.to_s
    @proc = block
    @data_store = {}
    @base_sql_dump = options[:base_sql_dump]
    self.class.loaded_scenarios[self.name] = self
  end

  def build
    ActiveRecord::Base.silence do
      self.proc.call(self)
    end
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
      scenario.do_build(environment)
    end
  end
  
  def do_build(environment = RAILS_ENV)
    log("Building scenario #{self.name}")
    log("  clearing database")
    self.class.clear_database(environment)
    if self.base_sql_dump.present?
      log("  loading base SQL dump")
      self.load_base_sql(environment)
    end
    log("  building data")
    self.build
    log("  dumping datastore")
    self.dump_data_store
    log("  dumping database")
    self.class.dump_database(self.sanitized_name)
    log("  done")    
  end
  
  def load_base_sql(environment = RAILS_ENV)
    log("    from #{self.base_sql_dump}")
    current_migrations = ActiveRecord::Base.connection.select_values("SELECT * FROM schema_migrations").sort
    dirname = File.dirname(self.base_sql_dump)
    filename = File.basename(self.base_sql_dump, ".sql")
    self.class.load_database(filename, environment, dirname)
    dump_migrations = ActiveRecord::Base.connection.select_values("SELECT * FROM schema_migrations").sort
    expected_migrations = current_migrations - dump_migrations
    
    raise "Migrations #{expected_migrations.join(",")} not present in base SQL dump file (#{self.base_sql_dump})" if expected_migrations.present?
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
  
  def log(msg)
    self.class.log(msg)
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