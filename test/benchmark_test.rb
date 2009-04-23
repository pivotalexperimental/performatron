require File.dirname(__FILE__) + "/test_helper"

# TODO: Consider moving some tests into benchmark_piece_test.rb
class BenchmarkTest < ActiveSupport::TestCase
  def setup
    Performatron::Sequence.loaded_sequences = {}
    Performatron::Scenario.loaded_scenarios = {}
    @sequence = Performatron::Sequence.new("test seq1") { |bench| bench.get "/1" }
    @sequence2 = Performatron::Sequence.new("test seq2") { |bench| bench.get "/2" }
    @scenario = Performatron::Scenario.new("test scn") {}
    @bench = Performatron::Benchmark.new(:scenarios => "test scn", :sequences => "test seq1")
    @bench2 = Performatron::Benchmark.new(:scenarios => "test scn", :sequences => ["test seq1", "test seq2"])
  end

  def test_human_readable_results
    @bench.generate_all_httperf # todo: rename this method?
    @bench.pieces.first.process_httperf_output(SAMPLE_HTTPERF_OUTPUT)
    output = @bench.pieces.first.human_readable_results
    assert output.include?("Average Reply Time: 254.3 ms")
  end

  def test_csv_results
    @bench.generate_all_httperf # todo: rename this method?
    @bench.pieces.first.process_httperf_output(SAMPLE_HTTPERF_OUTPUT)
    now = Time.now
    output = @bench.pieces.first.csv_results(now)
    assert output.include?("Timestamp,Scenario,Sequence,NumRequests,NumSessions,Rate,MaxConcurrency,AverageReplyTime,AverageReplyRate")
    expected_time = now.strftime("%Y-%m-%d %H:%M")
    data_line = output.split("\n")[1]
    assert_equal "\"#{expected_time}\",\"test scn\",\"test seq1\",100,100,1.0,5,254.3,6.9", data_line
  end

  def test_initialize__with_one_of_each
    assert_equal 1, @bench.pieces.length
    assert_equal @sequence, @bench.pieces[0].sequence
    assert_equal @scenario, @bench.pieces[0].scenario
  end

  def test_initialize__with_array
    assert_equal 2, @bench2.pieces.length
    assert_equal @sequence, @bench2.pieces[0].sequence
    assert_equal @scenario, @bench2.pieces[0].scenario
    assert_equal @sequence2, @bench2.pieces[1].sequence
    assert_equal @scenario, @bench2.pieces[1].scenario
  end

  def test_get_httperf
    assert_equal "/1", @bench.pieces[0].get_httperf
  end

  def test_generate_all_httperf
    FileUtils.rm_rf("/tmp/scenarios")
    assert !File.exist?("/tmp/scenarios/test_scn-test_seq1.bench")
    @bench.generate_all_httperf
    assert File.exist?("/tmp/scenarios/test_scn-test_seq1.bench")
  end

end