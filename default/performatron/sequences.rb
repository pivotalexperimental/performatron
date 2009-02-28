# Performatron::Sequence.new(:public_functionality) do |bench|
#   bench.get "/"
#   bench.get "/about"
#   bench.get "/signup"
#   bench.post "/search", {:query => "kitties"}
# end

# # Iterate over the data provided by the scenario to access each users profile
# Performatron::Sequence.new(:private_functionality) do |bench|  
#   bench[:users].each do |user|
#     bench.get "/login"
#     bench.post "/login", {}, :login => {:email_address => user["username"], :password => "test"}
#     bench.get "/users/#{user["username"]}/profile"
#     bench.delete "/login"
#   end
# end