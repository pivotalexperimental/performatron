require File.dirname(__FILE__) + "/test_helper"

class HttperfOutputTest < ActiveSupport::TestCase
  def setup
    @parser = Performatron::HttperfOutputParser.new
    @httperf_output = <<HTTPERF_OUTPUT
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
  end

  def test_max_concurrency
    assert_equal "5", @parser.parse(@httperf_output)[:max_concurrency]
  end

  # TODO: Test other values
end

