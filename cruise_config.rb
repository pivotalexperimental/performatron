# Project-specific configuration for CruiseControl.rb
Project.configure do |project|
  project.email_notifier.emails = ["chad+performatron-ci@pivotallabs.com", "dstevenson+performatron-ci@pivotallabs.com"]
  project.rake_task = 'rake DB_SOCKET=/var/run/mysqld/mysqld.sock'
end
