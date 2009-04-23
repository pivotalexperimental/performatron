module Performatron::BenchmarkDsl
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

  private

  def get_full_path(path, query_params)
    "#{path}#{query_params.empty? ? "" : "?#{query_params.to_query}"}"
  end
end
