require 'test/unit'
require 'rubygems'
gem 'activesupport'
require "active_support"
require 'active_support/test_case'
require "active_record"
ActiveRecord::Base.configurations = {'test' => {
             'adapter'  => 'mysql',
             'database' => 'pivotal_performance_test',
              'username' => 'root',
              'password' => 'password' 
          }}
RAILS_ENV="test"

ENV["SCHEMA"] = File.dirname(__FILE__) + "/schema.rb"
ActiveRecord::Base.establish_connection :test
load ENV["SCHEMA"]
require File.dirname(__FILE__) + "/../lib/performatron"
Performatron::Scenario.verbose = false

class Something < ActiveRecord::Base
  
end