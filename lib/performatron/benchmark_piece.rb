class Performatron::BenchmarkPiece
  attr_accessor :sequence
  attr_accessor :scenario
  attr_accessor :benchmark
  attr_accessor :buffer
  attr_accessor :httperf_output
  attr_accessor :httperf_stats

  def initialize
    @parser = Performatron::HttperfOutputParser.new
    @buffer = []
  end

  def get_httperf
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
    benchmark.rate
  end

  def num_sessions
    benchmark.num_sessions
  end

  def results
    {
      :scenario => scenario.name,
      :sequence => sequence.name,
      :num_sessions => benchmark.num_sessions,
      :num_sessions => num_sessions,
      :rate => benchmark.rate,
    }.merge(httperf_stats)
  end

  def human_readable_results
    Performatron::StandardFormatter.new.format(results)
  end

  def csv_results(time = Time.now)
    Performatron::CsvFormatter.new.format(results, time)
  end

  module BenchmarkDsl
    def get(path, query_params = {})
      output("#{get_full_path(path, query_params)}")
    end

    def post(path, query_params = {}, post_body = {})
      post_body_str = post_body.is_a?(Hash) ? post_body.to_query : post_body
      output("#{get_full_path(path, query_params)} method=POST contents='#{post_body_str}'")
    end

    def put(path, query_params = {}, post_body = {})
      post(path, query_params.merge("_method" => "put"), post_body)
    end

    def delete(path, query_params = {}, post_body = {})
      post(path, query_params.merge("_method" => "delete"), post_body)
    end

    def session
      yield
      output("")
    end

    private

    def get_full_path(path, query_params)
      "#{path}#{query_params.empty? ? "" : "?#{query_params.to_query}"}"
    end
  end
  include BenchmarkDsl

end
