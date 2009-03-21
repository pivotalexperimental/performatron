# Project-specific configuration for CruiseControl.rb
Project.configure do |project|
  project.email_notifier.emails = ["chad+performatron-ci@pivotallabs.com", "dstevenson+performatron-ci@pivotallabs.com"]
  project.build_command = 'rake DB_SOCKET=/tmp/mysql.sock'
end
