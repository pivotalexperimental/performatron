require File.dirname(__FILE__) + "/test_helper"

class TaskRunnerTest < ActiveSupport::TestCase
  attr_reader :task_runner
  def setup
    @task_runner = Performatron::TaskRunner.instance
    @task_runner.stubs(:puts)
    @local_config = {"remote" => false, "environment" => "perf"}
    @remote_config = {"remote" => true, "environment" => "perf", "host" => "test.host", "port" => "3000"}
    Performatron::Configuration.stubs(:instance).returns("benchmarkee" => @remote_config,
      "benchmarker" => @local_config)
  end
  
  
  def test_build_scenarios
    FileUtils.mkdir_p("/tmp/scenarios")
    Performatron::Scenario.expects(:build_all).with("test")
    task_runner.build_scenarios
    assert !File.exist?("/tmp/scenarios")
  end

  def test_build_scenarios__with_env_nobuild__doesnt_do_anything
    ENV["NOBUILD"] = "true"
    begin
      FileUtils.mkdir_p("/tmp/scenarios")
      Performatron::Scenario.expects(:build_all).never
      task_runner.build_scenarios
      assert File.exist?("/tmp/scenarios")
    ensure
      ENV["NOBUILD"] = nil
    end
  end
  
  
  def test_upload_benchmarks
    task_runner.expects(:run_task_on_benchmarkee_if_remote).with("performatron:upload_scenarios")
    task_runner.expects(:run_task_on_benchmarker_if_remote).with("performatron:upload_sequences")
    task_runner.upload_benchmarks
  end
  
  
  def test_run_task_on_benchmarkee
    task_runner.expects(:run_task).with(@remote_config, "task", {:var => "whatever"}, true)
    task_runner.send(:run_task_on_benchmarkee, "task", {:var => "whatever"}, true)
  end


  def test_run_task_on_benchmarker
    task_runner.expects(:run_task).with(@local_config, "task", {:var => "whatever"}, true)
    task_runner.send(:run_task_on_benchmarker, "task", {:var => "whatever"}, true)
  end
  
  
  def test_run_task__with_failure__raises_exception
    task_runner.expects(:system).returns(false)
    assert_raise(RuntimeError) { task_runner.send(:run_task, @local_config, "some:task") }
  end

  def test_run_task__when_local_no_vars__runs_simply_rake
    task_runner.expects(:system).with("rake some:task RAILS_ENV=perf").returns(true)
    task_runner.send(:run_task, @local_config, "some:task")
  end
  
  def test_run_task__when_local_with_vars__creates_rake_compatible_env_variables
    task_runner.expects(:system).with("rake some:task RAILS_ENV=perf 'TWO_WORDS=OmG' 'X=y'").returns(true)
    task_runner.send(:run_task, @local_config, "some:task", {:x => "y", "two_Words" => "OmG"})
  end
    
  def test_run_task__when_capturing__returns_output_of_cmd
    Tempfile.any_instance.stubs(:path).returns("/tmp/task_runner.tmp")
    File.open("/tmp/task_runner.tmp", "w") { |f| f.write "hello world!" }
    task_runner.expects(:system).with("rake some:task RAILS_ENV=perf 2>&1 | tee '/tmp/task_runner.tmp'").returns(true)
    assert_equal "hello world!", task_runner.send(:run_task, @local_config, "some:task", {}, true)
  end
    
  def test_run_task__when_remote_no_vars__runs_simply_capistrano
    task_runner.expects(:system).with("cap  perf some:task").returns(true)
    task_runner.send(:run_task, @remote_config, "some:task")
  end

  def test_run_task__when_remote_with_vars__creates_cap_compatible_vars
    task_runner.expects(:system).with("cap '-Stwo_words=OmG' '-Sx=y' perf some:task").returns(true)
    task_runner.send(:run_task, @remote_config, "some:task", {:x => "y", "two_Words" => "OmG"})
  end
  
  
  def test_run_benchmarks
    scenario = Struct.new(:sanitized_name).new("scenario_name")
    pieces = [Struct.new(:num_sessions, :rate, :scenario, :sanitized_name).new(10, 2.4, scenario, "benchmark_name")]
    benchmarks = [Struct.new(:pieces).new(pieces)]
    pieces.first.expects(:process_httperf_output).with("httperf_output_here")
    Performatron::Benchmark.expects(:loaded_benchmarks).returns(benchmarks)
    expect_command_ran_on_benchmarkee("performatron:load_scenario", :scenario => "scenario_name")
    expect_command_ran_on_benchmarker("performatron:run_httperf", {:host => "test.host", :port => "3000", :filename => '/tmp/scenarios/benchmark_name.bench', :rate => 2.4, :num_sessions => 10, :header => nil}, true).returns("httperf_output_here")
    task_runner.run_benchmarks
  end

  def test_run_benchmarks__with_basic_auth
    Performatron::Configuration.stubs(:instance).returns("benchmarkee" => @remote_config.merge("basic_auth" => {"username" => "david", "password" => "pass"}), "benchmarker" => @local_config)
    scenario = Struct.new(:sanitized_name).new("scenario_name")
    pieces = [Struct.new(:num_sessions, :rate, :scenario, :sanitized_name).new(10, 2.4, scenario, "benchmark_name")]
    benchmarks = [Struct.new(:pieces).new(pieces)]
    pieces.first.expects(:process_httperf_output).with("httperf_output_here")
    Performatron::Benchmark.expects(:loaded_benchmarks).returns(benchmarks)
    expect_command_ran_on_benchmarkee("performatron:load_scenario", :scenario => "scenario_name")
    expect_command_ran_on_benchmarker("performatron:run_httperf", {:host => "test.host", :port => "3000", :filename => '/tmp/scenarios/benchmark_name.bench', :rate => 2.4, :num_sessions => 10, :header => "Authorization: Basic ZGF2aWQ6cGFzcw==\\n"}, true).returns("httperf_output_here")
    task_runner.run_benchmarks
  end


  def test_print_benchmark_results
    piece = mock("piece")
    piece.expects(:print_results)
    benchmarks = [Struct.new(:pieces).new([piece])]
    Performatron::Benchmark.expects(:loaded_benchmarks).returns(benchmarks)
    task_runner.print_benchmark_results
  end
  
  
  private
  
  def expect_command_ran_on_benchmarkee(cmd, options = nil, capture = nil)
    task_runner.expects(:run_task_on_benchmarkee).with(*[cmd, options, capture].compact)
  end

  def expect_command_ran_on_benchmarker(cmd, options = nil, capture = nil)
    task_runner.expects(:run_task_on_benchmarker).with(*[cmd, options, capture].compact)
  end
end