class Performatron::Benchmark
  cattr_accessor :loaded_benchmarks
  cattr_accessor :default_rate
  cattr_accessor :default_num_sessions

  self.default_rate = 1.0
  self.default_num_sessions = 100
  self.loaded_benchmarks = []

  attr_reader :sequence
  attr_reader :scenario
  attr_reader :pieces
  attr_reader :rate
  attr_reader :num_sessions

  def initialize(options)
    @sequences = Array(options[:sequences])
    @scenarios = Array(options[:scenarios])
    @rate = options[:rate] || default_rate
    @num_sessions = options[:num_sessions] || default_num_sessions
    @pieces = []
    @sequences.each do |seq_name|
      @scenarios.each do |scn_name|
        seq = Performatron::Sequence.loaded_sequences[seq_name.to_s]
        scn = Performatron::Scenario.loaded_scenarios[scn_name.to_s]
        raise "unable to find sequence #{seq_name}" unless seq
        raise "unable to find scenario #{scn_name}" unless scn
        piece = Performatron::BenchmarkPiece.new
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
end