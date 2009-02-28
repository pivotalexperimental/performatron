# # Run the 1000-users scenario against the public functionality sequence
# # using the default connection settings
# Performatron::Benchmark.new(
#     :scenarios => :thousand_users,
#     :sequences => :public_functionality
# )


# # Run the each scenario against the each sequence (one at a time)
# # making 50 requests per second for 500 requests
# Performatron::Benchmark.new(
#     :scenarios => [:hundred_users, :thousand_users]
#     :sequences => [:public_functionality, :private_functionality]
#     :rate => 50.0,
#     :num_requests => 500
# )