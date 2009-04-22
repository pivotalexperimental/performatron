class Performatron::HttperfOutputParser
  def parse
    self.httperf_stats = {}
    self.httperf_stats[:max_concurrency] = output.match(/(\d+) concurrent connections/)[1]
    self.httperf_stats[:reply_rate_avg] = output.match(/Reply rate.*avg (\d+\.\d+)/)[1]
    self.httperf_stats[:reply_rate_max] = output.match(/Reply rate.*max (\d+\.\d+)/)[1]
    self.httperf_stats[:reply_rate_min] = output.match(/Reply rate.*min (\d+\.\d+)/)[1]
    self.httperf_stats[:reply_rate_stddev] = output.match(/Reply rate.*stddev (\d+\.\d+)/)[1]
    self.httperf_stats[:reply_time_avg] = output.match(/Reply time.*response (\d+.\d+)/)[1]
    self.httperf_stats[:responses_not_found] = output.match(/Reply status.*4xx=(\d+)/)[1]
    self.httperf_stats[:responses_error] = output.match(/Reply status.*5xx=(\d+)/)[1]    
  end
end
