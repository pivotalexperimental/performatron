# Performatron::Scenario.new(:thousand_users) do |scenario|
#   1.upto(1000) do |i|
#     User.create!(:username => "user_#{i}", :password => "test")
#   end
# end


# # By storing ActiveRecord objects in the scenario[] hash, the attributes of those objects
# # will be available during the benchmark.
# Performatron::Scenario.new(:hundred_users) do |scenario|
#   scenario[:users] = []
#   1.upto(100) do |i|
#     scenario[:users] << User.create!(:username => "user_#{i}", :password => "test")
#   end
# end


# Performatron::Scenario.new(:production_plus_1k_users, :base_sql_dump => "tmp/cache/prod.sql") do |scenario|
#   1000.times { Factory(:user) }
# end