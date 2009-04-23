class Performatron::StandardFormatter
  def format(results)
    results = <<RESULTS
Results for Scenario: #{results[:scenario]}, Sequence: #{results[:sequence]}:
  Total Requests Made: #{results[:num_sessions]} (#{results[:num_sessions]} sessions)
  Request Rate: #{results[:rate]} new requests/sec
  Concurrency: #{results[:max_concurrency]} requests/sec
    Average Reply Time: #{results[:reply_time_avg]} ms
    Average Reply Rate: #{results[:reply_rate_avg]} reply/s
RESULTS

    results
  end
end