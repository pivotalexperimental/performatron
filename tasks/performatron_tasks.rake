namespace :performatron do
  desc "Dump each scenario to a seperate SQL & YAML file in /tmp/scenarios"
  task :build_scenarios => :init do
    Performatron::TaskRunner.instance.build_scenarios
  end

  desc "Load each scenario's datastore from YAML files in /tmp/scenarios"
  task :load_datastores => :init do
    Performatron::Scenario.load_all_datastores
  end

  desc "Dump each scenario to a seperate SQL file in /tmp/scenarios"
  task :build_benchmarks => :init do
    Performatron::Benchmark.build_all
  end

  desc "Loads SCENARIO from /tmp/scenarios/SCENARIO.sql"
  task :load_scenario => :init do
    Performatron::Scenario.load_database(ENV["SCENARIO"])
  end

  task :upload_scenarios do
    # empty locally
  end

  task :upload_sequences do
    # empty locally
  end

  task :upload_benchmarks => :init do
    Performatron::TaskRunner.instance.upload_benchmarks
  end

  task :run_benchmarks => :init do
    Performatron::TaskRunner.instance.run_benchmarks
  end

  task :print_benchmark_results => :init do
    Performatron::TaskRunner.instance.print_benchmark_results
  end

  task :init => :environment do
    ENV["DEPLOY_ENV"] ||= "performance"
    require File.join(RAILS_ROOT, "lib", "performatron", "scenarios")
    require File.join(RAILS_ROOT, "lib", "performatron", "sequences")
    require File.join(RAILS_ROOT, "lib", "performatron", "benchmarks")
  end

  desc "Run Performatron benchmark"
  task :benchmark => [:build_scenarios, :load_datastores, :build_benchmarks, :upload_benchmarks, :run_benchmarks, :print_benchmark_results] do

  end

  task :run_httperf do
    options = ["--hog","--session-cookie", "--server=#{ENV["HOST"]}", "--wsesslog=#{ENV["NUM_SESSIONS"]},0,#{ENV["FILENAME"]}", "--rate=#{ENV["RATE"]}"]
    options << "--port=#{ENV["PORT"]}" if ENV["PORT"]
    options << "--add-header='#{ENV["HEADER"]}'" if ENV["HEADER"]
    cmd = "httperf #{options.join(" ")} 2>&1"
    puts "Running #{cmd}"
    system(cmd)
  end
end