class Performatron::BenchmarkPiece
  attr_accessor :sequence
  attr_accessor :scenario
  attr_accessor :benchmark
  attr_accessor :buffer
  attr_accessor :httperf_output
  attr_accessor :httperf_stats

  include Performatron::Sequence::Dsl

  def initialize
    @parser = Performatron::HttperfOutputParser.new
  end

  def get_httperf
    self.buffer = []
    self.sequence.proc.call(self)
    self.buffer.join("\n")
  end

  def output(str)
    buffer << str
  end

  def sanitized_name
    "#{scenario.sanitized_name}-#{sequence.sanitized_name}"
  end

  def process_httperf_output(output)
    self.httperf_output = output
    self.httperf_stats= @parser.parse(output)
  end

  def [](key)
    self.scenario[key]
  end

  def rate
    benchmark.rate / buffer.size
  end

  def num_sessions
    (benchmark.num_requests / buffer.size).to_i + 1
  end

  def results
    {
      :scenario => scenario.name,
      :sequence => sequence.name,
      :num_requests => benchmark.num_requests,
      :num_sessions => num_sessions,
      :request_rate => benchmark.rate,
    }.merge(httperf_stats)
  end

  def human_readable_results
    Performatron::StandardFormatter.new.format(results)
  end

  def csv_results(time = Time.now)
    Performatron::CsvFormatter.new.format(results, time)
  end
end
