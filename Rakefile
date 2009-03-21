require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'test/db_helper'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the performatron plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the performatron plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Performatron'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :test do
  desc 'Build the test database with options [DB_USER=user] [DB_PASSWORD=password]'
  task :build_database do
    %x( mysqladmin --user=#{ENV['DB_USER']} --password=#{ENV['DB_PASSWORD']} create performatron_test )
  end

  desc 'Drop the test database with options [DB_USER=user] [DB_PASSWORD=password]'
  task :drop_database do
    %x( mysqladmin --user=#{ENV['DB_USER']} --password=#{ENV['DB_PASSWORD']} -f drop performatron_test )
  end

  desc 'Rebuild the test database with options [DB_USER=user] [DB_PASSWORD=password]'
  task :rebuild_database => [:drop_database, :build_database]
end