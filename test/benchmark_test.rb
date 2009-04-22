require File.dirname(__FILE__) + "/test_helper"

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

  def test_can_print_their_results
#    piece = Performatron::Benchmark::Piece.new
#    piece.process_httperf_output(@httperf_output)
    @bench.generate_all_httperf # todo: rename this method?
    httperf_output = <<HTTPERF_OUTPUT
Maximum connect burst length: 1

Total: connections 301 requests 301 replies 301 test-duration 43.335 s

Connection rate: 6.9 conn/s (144.0 ms/conn, <=5 concurrent connections)
Connection time [ms]: min 65.7 avg 261.7 max 973.6 median 254.5 stddev 169.4
Connection time [ms]: connect 7.4
Connection length [replies/conn]: 1.000

Request rate: 6.9 req/s (144.0 ms/req)
Request size [B]: 143.0

Reply rate [replies/s]: min 6.8 avg 6.9 max 7.2 stddev 0.1 (8 samples)
Reply time [ms]: response 254.3 transfer 0.0
Reply size [B]: header 283.0 content 12.0 footer 0.0 (total 295.0)
Reply status: 1xx=0 2xx=301 3xx=0 4xx=0 5xx=0

CPU time [s]: user 6.70 system 25.72 (user 15.5% system 59.4% total 74.8%)
Net I/O: 3.0 KB/s (0.0*10^6 bps)

Errors: total 0 client-timo 0 socket-timo 0 connrefused 0 connreset 0
Errors: fd-unavail 0 addrunavail 0 ftab-full 0 other 0

Session rate [sess/s]: min 6.80 avg 6.95 max 7.20 stddev 0.14 (301/301)
Session: avg 1.00 connections/session
Session lifetime [s]: 0.3
Session failtime [s]: 0.0
Session length histogram: 0 301
** Invoke performatron:print_benchmark_results (first_time)
** Invoke performatron:init
** Execute performatron:print_benchmark_results
HTTPERF_OUTPUT
    @bench.pieces.first.process_httperf_output(httperf_output)
    output = @bench.pieces.first.human_readable_results
    assert output.include?("Average Reply Time: 254.3 ms")
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