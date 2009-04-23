class Performatron::Sequence
  cattr_accessor :loaded_sequences
  cattr_accessor :verbose
  self.loaded_sequences = {}
  self.verbose = true

  attr_reader :name
  attr_reader :proc
  def initialize(name, options = {}, &block)
    @name = name.to_s
    @proc = block # This proc is executed in BenchmarkPiece#get_httperf
    self.class.loaded_sequences[self.name] = self
  end

  def build
    Module.new()
  end

  def sanitized_name
    name.gsub(/\W+/, "_")
  end


end