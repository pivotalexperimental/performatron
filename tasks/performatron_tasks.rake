namespace :performatron do
  desc "Dump each scenario to a seperate SQL & YAML file in /tmp/scenarios"
  task :build_scenarios => :init do
    unless ENV["NOBUILD"]
      FileUtils.rm_rf("/tmp/scenarios")
      Performatron::Scenario.build_all("test")
    end
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
    #    require File.dirname(__FILE__) + "/../lib/pivotal_performance"
    Performatron::Scenario.load_database(ENV["SCENARIO"])
  end


  task :upload_scenarios do
    # empty locally
  end
  task :upload_sequences do
    # empty locally
  end

  task :upload_benchmarks => :init do
    run_task_on_benchmarkee("performatron:upload_scenarios")
    run_task_on_benchmarker("performatron:upload_sequences")
  end

  task :run_benchmarks => :init do
    Performatron::Benchmark.loaded_benchmarks.each do |bench|
      bench.pieces.each do |piece|
        victim_config = Performatron::Configuration.instance["benchmarkee"]
        do_load_scenario(piece.scenario.sanitized_name)
        output = do_run_httperf(:filename => "/tmp/scenarios/#{piece.sanitized_name}.bench", :rate => piece.rate, :num_sessions => piece.num_sessions, :host => victim_config["host"])
        piece.process_httperf_output(output)
      end
    end
  end

  task :print_benchmark_results => :init do
    Performatron::Benchmark.loaded_benchmarks.each do |bench|
      bench.pieces.each do |piece|
        puts "**********************************************************************"
        piece.print_results
        puts
      end
    end
  end

  task :init => :environment do
    ENV["DEPLOY_ENV"] ||= "performance"
    require File.join(RAILS_ROOT, "lib", "performatron", "scenarios")
    require File.join(RAILS_ROOT, "lib", "performatron", "sequences")
    require File.join(RAILS_ROOT, "lib", "performatron", "benchmarks")
  end

  task :benchmark => [:build_scenarios, :load_datastores, :build_benchmarks, :upload_benchmarks, :run_benchmarks, :print_benchmark_results] do

  end

  task :run_httperf do
    global_options = "--hog --session-cookie"
    cmd = "httperf #{global_options} --server=#{ENV["HOST"]} --wsesslog=#{ENV["NUM_SESSIONS"]},0,#{ENV["FILENAME"]} --rate=#{ENV["RATE"]} 2>&1"
    puts "Running #{cmd}"
    system(cmd)
  end
end

def do_load_scenario(scenario)
  run_task_on_benchmarkee("performatron:load_scenario", {:scenario => scenario})
end

def do_run_httperf(options)
  run_task_on_benchmarker("performatron:run_httperf", options, true)
end

def run_task_on_benchmarkee(task_name, env_variables = {}, capture_output = false)
  run_task(Performatron::Configuration.instance["benchmarkee"], task_name, env_variables, capture_output)
end

def run_task_on_benchmarker(task_name, env_variables = {}, capture_output = false)
  run_task(Performatron::Configuration.instance["benchmarker"], task_name, env_variables, capture_output)
end

def run_task(config, task_name, env_variables = {}, capture_output = false)
  if config["remote"]
    env_str = env_variables.collect{|k, v| "-S#{k.to_s.downcase}=#{v}"}.join(" ") + " "
    cmd = "cap #{env_str}#{config["environment"]} #{task_name}"
  else
    env_str = env_variables.collect{|k, v| "#{k.to_s.upcase}=#{v.to_s}"}.join(" ")
    cmd = "rake #{task_name} #{env_str}"
  end

  if capture_output
    tmpfile = Tempfile.new("performatron_output")
    tmpfile.close
    cmd += " 2>&1 | tee '#{tmpfile.path}'"
    puts "   --- running #{cmd.inspect}"
    raise "Unable to run #{task_name} (remote=#{config["remote"].inspect})" unless system(cmd)
    output = File.read(tmpfile.path)
    FileUtils.rm(tmpfile.path)
    output
  else
    puts "   --- running #{cmd.inspect}"
    raise "Unable to run #{task_name} (remote=#{config["remote"].inspect})" unless system(cmd)
  end

end
