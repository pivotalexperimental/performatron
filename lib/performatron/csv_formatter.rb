class Performatron::CsvFormatter
  def format(results, time)
    header = "Timestamp,Scenario,Sequence,NumRequests,NumSessions,Rate,MaxConcurrency,AverageReplyTime,AverageReplyRate"
    array = []
    array << time.strftime("%Y%m%d%H%M")
    array << results[:scenario]
    array << results[:sequence]
    array << results[:num_requests]
    array << results[:num_sessions]
    array << results[:request_rate]
    array << results[:max_concurrency]
    array << results[:reply_time_avg]
    array << results[:reply_rate_avg]
    header + "\n" + array.join(",")
  end
end
