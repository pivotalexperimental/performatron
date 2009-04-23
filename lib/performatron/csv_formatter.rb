class Performatron::CsvFormatter
  def format(results, time)
    header = "Timestamp,Scenario,Sequence,NumRequests,NumSessions,Rate,MaxConcurrency,AverageReplyTime,AverageReplyRate"
    array = []
    array << surround_with_quotes(time.strftime("%Y-%m-%d %H:%M"))
    array << surround_with_quotes(results[:scenario])
    array << surround_with_quotes(results[:sequence])
    array << results[:total_requests]
    array << results[:num_sessions]
    array << results[:rate]
    array << results[:max_concurrency]
    array << results[:reply_time_avg]
    array << results[:reply_rate_avg]
    header + "\n" + array.join(",")
  end

  def surround_with_quotes(string)
    '"' + string + '"'
  end
end
