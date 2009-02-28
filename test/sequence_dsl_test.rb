require File.dirname(__FILE__) + "/test_helper"

class BenchmarkHarness
  include Performatron::Sequence::Dsl

  attr_reader :scenario
  attr_accessor :buffer

  def initialize(scenario)
    @scenario = scenario
    self.buffer = []
  end

  def output(str)
    buffer << str
  end
end

class SequenceDslTest < ActiveSupport::TestCase
  def setup
    @benchmark = BenchmarkHarness.new(Performatron::Scenario.new("test scenario") {})
  end
  
  def test_get
    @benchmark.get "/hello/world"
    assert_equal ["/hello/world"], @benchmark.buffer
  end

  def test_get__with_query_params
    @benchmark.get "/hello/world", {:hello => "world"}
    assert_equal ["/hello/world?hello=world"], @benchmark.buffer
  end

  def test_post__with_body
    @benchmark.post "/hello/world", {}, {:body => "data"}
    assert_equal ["/hello/world method=POST contents='body=data'"], @benchmark.buffer
  end

  def test_post__with_query_params_and_body
    @benchmark.post "/hello/world", {:query => "param"}, {:body => "data"}
    assert_equal ["/hello/world?query=param method=POST contents='body=data'"], @benchmark.buffer
  end

  def test_put__with_body
    @benchmark.put "/hello/world", {}, {:body => "data"}
    assert_equal ["/hello/world?_method=put method=POST contents='body=data'"], @benchmark.buffer
  end

  def test_put__with_query_params_and_body
    @benchmark.put "/hello/world", {:query => "param"}, {:body => "data"}
    assert_equal ["/hello/world?_method=put&query=param method=POST contents='body=data'"], @benchmark.buffer
  end

  def test_delete
    @benchmark.delete "/hello/world"
    assert_equal ["/hello/world?_method=delete method=POST contents=''"], @benchmark.buffer
  end

  def test_delete__with_query_params
    @benchmark.delete "/hello/world", {:hello => "world"}
    assert_equal ["/hello/world?_method=delete&hello=world method=POST contents=''"], @benchmark.buffer
  end
end