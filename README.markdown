Performatron
==================
A language to write and execute benchmarks on rails applications.

How it works
------------

Define three sets of simple objects in lib/performatron:
 * Scenarios
 * Sequences
 * Benchmarks

Setup config/performatron.yml with the machine that will do the benchmarking (the benchmarker) and the machine that will
be tested against (the benchmarkee).  You'll also need a dedicated environment to run benchmarks against, unless you're
willing to reuse an existing environment and lose all data on it.

Executing rake performatron:benchmark then runs all benchmarks and prints out a summary. 

### Scenarios
A scenario represents the state of the database when a benchmark is run.  You might have multiple scenarios if you want
to understand how your the performance of your application will changes as it grows to 1000 users, 10000 users, etc.

Scenarios are built by simply creating objects in a block.  When the block starts, the database is completely empty.
When the block finishes, the state of the database is dumped in the form of a mysqldump file in /tmp/scenarios.

    # Declared in lib/performatron/scenarios.rb
    Performatron::Scenario.new(:thousand_users) do |scenario|
      1.upto(1000) do |i|
        User.create!(:username => "user_#{i}", :password => "test")
      end
    end

You can export data out of your scenario and make it available then the benchmark is run.  This is useful for iterating
over all your users and fetching their profiles, for example.

    Performatron::Scenario.new(:thousand_users) do |scenario|
      scenario[:important_users] = []
      1.upto(100) do |i|
        scenario[:important_users] << User.create!(:username => "important_user_#{i}", :password => "test")
      end
      1.upto(900) do |i|
        User.create!(:username => "user_#{i}", :password => "test")
      end
    end

The attributes of all ActiveRecord objects declared in exported data are dumped to a YAML file in /tmp/scenarios.

### Sequences
Sequences are a list of actions that you're interested in the performance of.  They can be any combination of GET, POST,
PUT, and DELETE requests in a row.  A simple example would be just to fetch the homepage:

    # Declared in lib/performatron/sequences.rb
    Performatron::Sequence.new(:homepage) do |bench|
      bench.get "/"
    end

Typically, sequences would tell a story, such as "a user logs in, checks their messages,
writes a message, and logs out".  By using the data exported from a scenario, you can check these stories for every
user in the scenario:

    Performatron::Sequence.new(:user_login_and_messaging) do |bench|
      bench[:users].each do |user|
        bench.get "/login"
        bench.post "/login", {}, :login => {:email_address => user["username"], :password => "test"}
        bench.get "/messages"
        bench.post "/messages/new", {}, :message => {:to_id => bench[:users].rand, :subject => "Hello world", :body => "Hi!"}
        bench.delete "/login"
      end
    end

### Benchmarks

Benchmarks are just pairs of sequences and scenarios.  They also include information on request rate and the number
of requests to make.  If you create a benchmark with multiple scenarios and/or multiple sequences, all possible combinations
will be tested.

    # Declared in lib/performatron/benchmarks.rb
    Performatron::Benchmark.new(
        :scenarios => :thousand_users,
        :sequences => :public_functionality
    )


Requirements
------------

 * Your application must use multistage capistrano
 * You can create a new or reuse an existing rails environment to benchmark against
 * Your local test and remote performance databases must use MySQL

Configuration
-------------

/config/performatron.yml

valid benchmarker options:
  remote: true or false (whether to use capitrano to execute commands or not)
  environment: the name of the multistage capistrano environment used to execute commands (you can test by running `cap XXX performatron:upload_scenarios`, which XXX is the name of the enviornment)

valid benchmarkee options:
  remote: see above
  environment: see above
  host: the host used when running httperf (must be accessible to the benchmarker)

Copyright (c) 2009 Pivotal Labs & David Stevenson, released under the MIT license
