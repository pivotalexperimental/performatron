class Performatron::Benchmark
  cattr_accessor :loaded_benchmarks
  cattr_accessor :default_rate
  cattr_accessor :default_num_requests

  self.default_rate = 1.0
  self.default_num_requests = 100
  self.loaded_benchmarks = []

  attr_reader :sequence
  attr_reader :scenario
  attr_reader :pieces
  attr_reader :rate
  attr_reader :num_requests

  def initialize(options)
    @sequences = Array(options[:sequences])
    @scenarios = Array(options[:scenarios])
    @rate = options[:rate] || default_rate
    @num_requests = options[:num_requests] || default_num_requests
    @pieces = []
    @sequences.each do |seq_name|
      @scenarios.each do |scn_name|
        seq = Performatron::Sequence.loaded_sequences[seq_name.to_s]
        scn = Performatron::Scenario.loaded_scenarios[scn_name.to_s]
        raise "unable to find sequence #{seq_name}" unless seq
        raise "unable to find scenario #{scn_name}" unless scn
        piece = Piece.new
        piece.benchmark = self
        piece.scenario = scn
        piece.sequence = seq
        @pieces << piece
      end
    end
    loaded_benchmarks << self
  end

  def generate_all_httperf(directory = "/tmp/scenarios")
    FileUtils.mkdir_p(directory)
    self.pieces.each do |piece|
      filename = "#{directory}/#{piece.sanitized_name}.bench"
      File.open(filename, "w") do |f|
        f.write(piece.get_httperf + "\n")
      end
    end
  end

  def self.build_all
    loaded_benchmarks.collect(&:generate_all_httperf)
  end

  class Piece
    attr_accessor :sequence
    attr_accessor :scenario
    attr_accessor :benchmark
    attr_accessor :buffer
    attr_accessor :httperf_output
    attr_accessor :httperf_stats

    include Performatron::Sequence::Dsl

    def initialize
#      @parser = HttpPerfOutputParser.new
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
      # stats= HttpPerfOutputParser.parse(output)

      self.httperf_output = output
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
#      StandardFormatter.new({:scenario => foo, :httperf_stats => httperf_stats})
#      CsvFormatter
      results = <<RESULTS
Results for Scenario: #{scenario.name}, Sequence: #{sequence.name}:
  Total Requests Made: #{benchmark.num_requests} (#{num_sessions} sessions)
  Request Rate: #{benchmark.rate} new requests/sec
  Concurrency: #{httperf_stats[:max_concurrency]} requests/sec
    Average Reply Time: #{httperf_stats[:reply_time_avg]} ms
    Average Reply Rate: #{httperf_stats[:reply_rate_avg]} reply/s
RESULTS
    end
  end
end