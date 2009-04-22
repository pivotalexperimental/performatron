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
end