require File.dirname(__FILE__) + "/test_helper"

class ScenarioTest < ActiveSupport::TestCase
  def setup
    Performatron::Scenario.loaded_scenarios = {}
    ActiveRecord::Base.connection.delete "DELETE FROM somethings"
  end

  def test_new_scenarios_are_added_to_loaded_scenarios
    assert Performatron::Scenario.loaded_scenarios.empty?
    scenario = Performatron::Scenario.new("test")
    assert Performatron::Scenario.loaded_scenarios.values.include?(scenario)
  end

  def test_build__runs_block
    block_run = false
    scenario = Performatron::Scenario.new("test") { block_run = true }
    assert !block_run
    scenario.build
    assert block_run
  end

  def test_clear_database__deletes_data
    ActiveRecord::Base.connection.insert("INSERT INTO somethings(name) VALUES ('hello world')")
    assert_equal 1, ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM somethings").to_i
    Performatron::Scenario.clear_database
    assert_equal 0, ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM somethings").to_i
  end

  def test_dump_database__dumps_data_and_schema_to_file
    filename = "/tmp/scenarios/scenario.sql"
    FileUtils.rm_rf("/tmp/scenarios")
    ActiveRecord::Base.connection.insert("INSERT INTO somethings(name) VALUES ('hello world')")
    assert_equal 1, ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM somethings").to_i
    assert !File.exist?(filename)
    Performatron::Scenario.dump_database
    assert File.exist?(filename)
    contents = File.read(filename)
    assert contents.include?("INSERT INTO `somethings`")
    assert contents.include?("CREATE TABLE `somethings`")
  end

  def test_load_database__loads_data_and_schema_to_file
    filename = "/tmp/scenarios/scenario.sql"
    File.open(filename, "w") do |f|
      f.write <<-SQL
DROP TABLE IF EXISTS `somethings`;
CREATE TABLE `somethings` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `number` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
INSERT INTO `somethings` VALUES (1,'hello world',NULL,NULL,NULL);
      SQL
    end
    assert_equal 0, ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM somethings").to_i
    Performatron::Scenario.load_database
    assert_equal 1, ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM somethings").to_i
  end

  def test_build_all__builds_all_loaded_scenarios
    blocks_run = 0
    scenario1 = Performatron::Scenario.new("test1") { blocks_run += 1 }
    scenario2 = Performatron::Scenario.new("test2") { blocks_run += 1 }
    assert_equal 0, blocks_run
    Performatron::Scenario.build_all
    assert_equal 2, blocks_run
  end

  def test_build_all__dumps_all_loaded_scenarios
    blocks_run = 0
    scenario1 = Performatron::Scenario.new("test1") { ActiveRecord::Base.connection.insert "INSERT INTO somethings(name) VALUES ('LOLZ')" }
    scenario2 = Performatron::Scenario.new("test2") { ActiveRecord::Base.connection.insert "INSERT INTO somethings(name) VALUES ('OMFG')" }
    FileUtils.rm_rf("/tmp/scenarios")
    Performatron::Scenario.build_all
    assert File.exist?("/tmp/scenarios/test1.sql")
    assert File.exist?("/tmp/scenarios/test2.sql")
    assert File.exist?("/tmp/scenarios/test1.yml")
    assert File.exist?("/tmp/scenarios/test2.yml")
    assert File.read("/tmp/scenarios/test1.sql").include?("LOLZ")
    assert File.read("/tmp/scenarios/test2.sql").include?("OMFG")
    assert !File.read("/tmp/scenarios/test2.sql").include?("LOLZ")
  end
  
  def test_do_build__with_base_sql_file__builds_new_data_on_top
    scenario = Performatron::Scenario.new("test1", :base_sql_dump => File.dirname(__FILE__) + "/base.sql") do
      ActiveRecord::Base.connection.insert "INSERT INTO somethings(name) VALUES ('LOLZ')"
    end
    scenario.do_build
    assert_equal 1, ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM others").to_i    
    assert_equal 2, ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM somethings").to_i    
  end

  def test_load_base_sql__fails_when_migrations_differ
    Performatron::Scenario.clear_database
    ActiveRecord::Base.connection.insert "INSERT INTO `schema_migrations` VALUES ('20110101000000')"        
    scenario = Performatron::Scenario.new("test1", :base_sql_dump => File.dirname(__FILE__) + "/base.sql") do
      ActiveRecord::Base.connection.insert "INSERT INTO somethings(name) VALUES ('LOLZ')"
    end
    assert_raise(RuntimeError) {
      scenario.load_base_sql
    }
  end

  def test_data_store
    scenario1 = Performatron::Scenario.new("test1") { |scenario| scenario[:users] = "david" }
    scenario1.build
    assert_equal({"users" => "david"}, scenario1.data_store)
  end

  def test_dump_data_store
    FileUtils.rm_f("/tmp/scenarios/test1.yml")
    scenario1 = Performatron::Scenario.new("test1") { |scenario| scenario[:something] = Something.create(:name => "david", :number => 5) }
    scenario1.build
    scenario1.dump_data_store
    assert File.exist?("/tmp/scenarios/test1.yml")
    assert File.read("/tmp/scenarios/test1.yml").include?("david")
  end

  def test_load_data_store
    File.open("/tmp/scenarios/test1.yml", "w") do |f|
      f.write <<YAML
---
something: 
  name: david
  number: 5
  id: 1
YAML
    end
    scenario1 = Performatron::Scenario.new("test1") { }
    scenario1.load_data_store
    assert_equal "david", scenario1.data_store["something"]["name"]
  end
end