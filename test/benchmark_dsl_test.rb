require File.dirname(__FILE__) + "/test_helper"

class BenchmarkDslTest < ActiveSupport::TestCase
  def setup
    @benchmark = Performatron::BenchmarkPiece.new
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

  def test_session__creates_a_blank_line_after_the_block_is_executed
    @benchmark.session do
      @benchmark.get "/hello/world"
      @benchmark.get "/goodbye/world"
    end
    @benchmark.session do
      @benchmark.get "/foo/bar"
      @benchmark.get "/baz"
    end
    assert_equal(
      [
        "/hello/world",
        "/goodbye/world",
        "",
        "/foo/bar",
        "/baz",
        ""
      ],
      @benchmark.buffer
    )
  end
end