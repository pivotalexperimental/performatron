class Performatron::TaskRunner
  include Singleton
  
  def build_scenarios
    unless ENV["NOBUILD"]
      FileUtils.rm_rf("/tmp/scenarios")
      Performatron::Scenario.build_all("test")
    end
  end
  
  def upload_benchmarks
    run_task_on_benchmarkee_if_remote("performatron:upload_scenarios")
    run_task_on_benchmarker_if_remote("performatron:upload_sequences")
  end
  
  def run_benchmarks
    Performatron::Benchmark.loaded_benchmarks.each do |bench|
      bench.pieces.each do |piece|
        victim_config = Performatron::Configuration.instance["benchmarkee"]
        run_task_on_benchmarkee("performatron:load_scenario", {:scenario => piece.scenario.sanitized_name})
        httperf_options = {:filename => "/tmp/scenarios/#{piece.sanitized_name}.bench", 
                                :rate => piece.rate, :num_sessions => piece.num_sessions, 
                                :host => victim_config["host"],
                                :port => victim_config["port"] || "80",
                                :header => basic_auth_header(victim_config)}
        output = run_task_on_benchmarker("performatron:run_httperf", httperf_options, true)
        piece.process_httperf_output(output)
      end
    end
  end
  
  def print_benchmark_results
    Performatron::Benchmark.loaded_benchmarks.each do |bench|
      bench.pieces.each do |piece|
        puts "**********************************************************************"
        puts piece.print_results
        puts
      end
    end    
  end
  
  private
  
  def basic_auth_header(config)
    if config["basic_auth"]
      user = config["basic_auth"]["username"]
      pass = config["basic_auth"]["password"]
      raise "Must specify 'username' and 'password' options under 'basic_auth' in performatron.yml" unless user && pass
      "Authorization: Basic #{Base64.encode64("#{user}:#{pass}").strip}\\n"
    end
  end
  
  def run_task_on_benchmarkee(task_name, env_variables = {}, capture_output = false)
    run_task(Performatron::Configuration.instance["benchmarkee"], task_name, env_variables, capture_output)
  end

  def run_task_on_benchmarker(task_name, env_variables = {}, capture_output = false)
    run_task(Performatron::Configuration.instance["benchmarker"], task_name, env_variables, capture_output)
  end

  def run_task_on_benchmarkee_if_remote(task_name, env_variables = {}, capture_output = false)
    config = Performatron::Configuration.instance["benchmarkee"]
    run_task(config, task_name, env_variables, capture_output) if config["remote"]
  end

  def run_task_on_benchmarker_if_remote(task_name, env_variables = {}, capture_output = false)
    config = Performatron::Configuration.instance["benchmarker"]
    run_task(config, task_name, env_variables, capture_output) if config["remote"]
  end

  def run_task(config, task_name, env_variables = {}, capture_output = false)
    if config["remote"]
      env_str = env_variables.collect{|k, v| v.nil? ? nil : "'-S#{k.to_s.downcase}=#{v}'"}.compact.join(" ") + " "
      cmd = "cap #{env_str}#{config["environment"]} #{task_name}".strip
    else
      env_str = env_variables.collect{|k, v| v.nil? ? nil : "'#{k.to_s.upcase}=#{v.to_s}'"}.compact.join(" ")
      cmd = "rake #{task_name} RAILS_ENV=#{config["environment"]} #{env_str}".strip
    end

    if capture_output
      tmpfile = Tempfile.new("performatron_output")
      tmpfile.close
      cmd += " 2>&1 | tee '#{tmpfile.path}'"
      puts "   --- running #{cmd.inspect}"
      raise "Unable to run #{task_name} (remote=#{config["remote"].inspect}, cmd='#{cmd}')" unless system(cmd)
      output = File.read(tmpfile.path)
      FileUtils.rm(tmpfile.path)
      output
    else
      puts "   --- running #{cmd.inspect}"
      raise "Unable to run #{task_name} (remote=#{config["remote"].inspect}, cmd='#{cmd}')" unless system(cmd)
    end

  end
end