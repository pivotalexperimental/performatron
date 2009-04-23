require File.dirname(__FILE__) + "/test_helper"

class HttperfOutputTest < ActiveSupport::TestCase
  def setup
    @parser = Performatron::HttperfOutputParser.new
  end

  def test_total_requests
    assert_equal "301", @parser.parse(SAMPLE_HTTPERF_OUTPUT)[:total_requests]
  end

  def test_max_concurrency
    assert_equal "5", @parser.parse(SAMPLE_HTTPERF_OUTPUT)[:max_concurrency]
  end

  # TODO: Test other values
end

