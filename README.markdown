Performatron
==================
A language to write and execute benchmarks on rails applications.

It uses object mother patterns to build benchmarking scenarios,
`capistrano` to set up them on a benchmarking server, and `httperf` to test them against your application.

Community
---------
 * Pivotal Labs Open Source Mailing List: http://groups.google.com/group/pivotallabsopensource
 * Pivotal Tracker Bug/Feature Tracker: http://www.pivotaltracker.com/projects/10679
 * GitHub Source Code Repository: http://github.com/pivotal/performatron/tree/master
 * Continuous Integration: http://ci.pivotallabs.com:3333/builds/Performatron

Installing
----------
    ./script/plugin install git://github.com/pivotal/performatron.git

You should also check the requirements below, ensure that you have `httperf` installed on your benchmarker, and that the following line exists in your `Capfile`:

    Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }   

Configuration
-------------
`/config/performatron.yml`

    An example of performatron.yml is:
      results_format: human_readable
      
      default:
        benchmarker:
          remote: false

        benchmarkee:
          remote: true
          environment: performance
          host: localhost
          port: 80

      demo:
        benchmarker:
          remote: true
          environment: test

        benchmarkee:
          remote: true
          environment: demo
          host: demo.host.com
          basic_auth:
            username: performatron
            password: your_basic_auth_password

    results_format: Can be 'human_readable' or 'csv'

    setup name (default):
      Performatron supports multiple setups (benchmarker + benchmarkee) for
      your various benchmarking setups.  When you first install Performatron,
      a default setup is generated. You can tell Performatron to run a setup
      by running `rake performatron:benchmark SETUP=demo`.

    valid benchmarker options:
      remote:      true or false (whether to use capitrano to execute commands or not)
      environment: the name of the multistage capistrano environment used to execute
                   commands (you can test by running `cap XXX performatron:upload_scenarios`,
                   in which XXX is the name of the enviornment)

    valid benchmarkee options:
      remote: see above
      environment: see above
      disable_scenarios: true if you don't want to wipe out the database on the benchmarkee and
                         disable the use of scenarios completely. See section scenarios below.
      host: the host used when running httperf (must be accessible to the benchmarker)
      port: the port used when running httperf (optional setting defaults to port 80)
      basic_auth: (optional, http basic auth creds used to access the benchmarkee)
        username: xxx
        password: yyy

Running
-------
To run, execute the following rake task:

    bash$ rake performatron:benchmark

When you run the benchmarks, `httperf` runs the given sequences over and over against the benchmarkee server, creating new requests at the rate you desire.
If the server is able to keep up with these requests, the existing ones will be answered before new ones are created.  If not, they begin to pile up and each
takes longer and longer.  When this happens, you've saturated your system.

It's often interesting to benchmark with a rate of 0, which means make requests sequentially instead of concurrently.

How it works
------------

Define three sets of simple objects in lib/performatron:

 * Scenarios
 * Sequences
 * Benchmarks

Setup `config/performatron.yml` with the machine that will do the benchmarking (the benchmarker) and the machine that will
be tested against (the benchmarkee).  You'll also need a dedicated environment to run benchmarks against, unless you're
willing to reuse an existing environment and lose all data on it.

Executing the following rake task then runs all benchmarks and prints out a summary:

    bash$ rake performatron:benchmark
    **********************************************************************
    Results for Scenario: hundred_users, Sequence: homepage
      Total Requests Made: 1000 (1000 sessions)
      Request Rate: 10 new requests/sec
        Concurrency: 5 requests/sec
        Average Reply Time: 304.7 ms
        Average Reply Rate: 9.9 reply/s


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

#### Using existing data as a base for scenarios

You can use an existing SQL dump (such as a production database dump) as a starting point for generating your scenarios
The dump is loaded before the block of code is evaluated when the scenario is built.  This is a great way to take an existing
dataset and add more data onto it to see how it performs in the future, while keeping test runs repeatable.

    Performatron::Scenario.new(:production_plus_1k, :base_sql_dump => "tmp/production.sql") do |scenario|
      1000.times { User.create! }
    end
    
#### Disabling scenarios entirely and not clearing the database on the benchmarkee

By default, performatron enables scenario loading.  This will wipe out all the current data in the database on the benchmarkee
when performance tests are run.  This is good, because it provides a deterministic test environment for running performance tests.

If you want to disable this feature, you can set the `disable_scenarios` option to true
under the `benchmarkee` hash in `performatron.yml`. If you enable this option, 
you still need to define a scenario and pass it in to your benchmark, 
but it will NOT be loaded on the benchmarkee.

### Sequences
Sequences are a list of actions that you're interested in the performance of.  They can be any combination of GET, POST,
PUT, and DELETE requests in a row.  A simple example would be just to fetch the homepage:

    # Declared in lib/performatron/sequences.rb
    Performatron::Sequence.new(:homepage) do |bench|
      bench.get "/"
    end

The #get and #delete methods take three parameters: URL, the URL Parameters Hash, and an optional 'think time':

    bench.get "/users/1", {:url_param => 'value1'}, 2.0
    bench.delete "/users/1", {:url_param => 'value1'}, 2.0

The #post and #put methods take four parameters: URL, URL Parameters Hash, Post body Hash, and the optional 'think time':

    bench.post "/login", {:url_param => 'value1'}, :login => {:email_address => user["username"], :password => "test"}, 2.0
    bench.put "/users/1", {:url_param => 'value1'}, :user => {:name => "John Doe"}, 2.0

Typically, sequences would tell a story, such as "a user logs in, checks their messages for a few (4, in this case) seconds,
writes a message, and logs out".  By using the data exported from a scenario, you can check these stories for every
user in the scenario:

    Performatron::Sequence.new(:user_login_and_messaging) do |bench|
      bench[:users].each do |user|
        bench.get "/login"
        bench.post "/login", {}, :login => {:email_address => user["username"], :password => "test"}
        bench.get "/messages", {}, 4
        bench.post "/messages/new", {}, :message => {:to_id => bench[:users].rand, :subject => "Hello world", :body => "Hi!"}
        bench.delete "/login"
      end
    end

Sequences also support the Httperf concept of "sessions", which are independent sessions with independent tcp connections,
cookies, etc.  Here an example with each user having their own session:

    Performatron::Sequence.new(:multiple_user_login_and_messaging) do |bench|
      bench[:users].each do |user|
        bench.session do
          bench.get "/login"
          bench.post "/login", {}, :login => {:email_address => user["username"], :password => "test"}
          bench.get "/messages"
          bench.post "/messages/new", {}, :message => {:to_id => bench[:users].rand, :subject => "Hello world", :body => "Hi!"}
        end
      end
    end


### Benchmarks

Benchmarks are just pairs of sequences and scenarios.  They also include information on request rate and the number
of requests to make.

    # Declared in lib/performatron/benchmarks.rb
    Performatron::Benchmark.new(
        :scenarios => :hundred_users,
        :sequences => :homepage
        :rate => 100,
        :num_sessions => 1000
    )

If you create a benchmark with multiple scenarios and/or multiple sequences, all possible combinations
will be tested.

    # Declared in lib/performatron/benchmarks.rb
    Performatron::Benchmark.new(
        :scenarios => :hundred_users,
        :sequences => [:homepage, :user_login_and_messaging]
        :rate => 10,
        :num_sessions => 200
    )


Requirements
------------

 * Your application must use multistage capistrano
 * You can create a new or reuse an existing rails environment to benchmark against
 * Your local test and remote performance databases must use MySQL

Results
-------

Each benchmark will print out 3 important pieces of information

    **********************************************************************
    Results for Scenario: hundred_users, Sequence: homepage
      Total Requests Made: 1000 (1000 sessions)
      Request Rate: 10 new requests/sec
        Concurrency: 5 requests/sec
        Average Reply Time: 304.7 ms
        Average Reply Rate: 9.9 reply/s

* *Concurrency*.  This is the maximum number of simultaneous requests that were outstanding at once.  This number should be less than the request rate, or requests started piling up on top of each other.
* *Reply Time* in ms.  You want this to be as low as possible.
* *Reply Rate* in req/sec. It should be close to the request rate, or the system is not keeping up with the load.

Copyright (c) 2009-2010 Pivotal Labs and David Stevenson. This software is licensed under the MIT License.
