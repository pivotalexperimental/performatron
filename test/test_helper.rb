require 'test/unit'
require 'rubygems'
gem 'activesupport'
require "active_support"
require 'active_support/test_case'
require "active_record"
require 'test/db_helper'
gem "mocha"
require "mocha"

db_config = {
  'adapter'  => 'mysql',
  'database' => 'performatron_test',
  'username' => ENV['DB_USER'],
  'password' => ENV['DB_PASSWORD']
}

db_config['socket'] = ENV['DB_SOCKET'] if ENV['DB_SOCKET']

ActiveRecord::Base.configurations = {'test' => db_config}

RAILS_ENV="test"
ENV["SCHEMA"] = File.dirname(__FILE__) + "/schema.rb"
ActiveRecord::Base.establish_connection :test

begin
  load ENV["SCHEMA"]
rescue Mysql::Error => e
  p e
  p '----------------------------------------------------------------------------------------------------------------'
  p "You need to create the test database by running 'rake test:build_database' [DB_USER=user] [DB_PASSWORD=password]"
  p '----------------------------------------------------------------------------------------------------------------'
  exit 1
end

require File.dirname(__FILE__) + "/../lib/performatron"
Performatron::Scenario.verbose = false

class Something < ActiveRecord::Base
  
end