require 'test/unit'
require 'rubygems'
gem 'activesupport'
require "active_support"
require 'active_support/test_case'
require "active_record"
require 'test/db_helper'

ActiveRecord::Base.configurations = {'test' => {
             'adapter'  => 'mysql',
             'database' => 'performatron_test',
              'username' => ENV['DB_USER'],
              'password' => ENV['DB_PASSWORD'] 
          }}

RAILS_ENV="test"
ENV["SCHEMA"] = File.dirname(__FILE__) + "/schema.rb"

ActiveRecord::Base.establish_connection :test

begin
  load ENV["SCHEMA"]
rescue 
  p '----------------------------------------------------------------------------------------------------------------'
  p "You need to create the test database by running 'rake test:build_database' [DB_USER=user] [DB_PASSWORD=password]"
  p '----------------------------------------------------------------------------------------------------------------'
  exit 1
end

require File.dirname(__FILE__) + "/../lib/performatron"
Performatron::Scenario.verbose = false

class Something < ActiveRecord::Base
  
end