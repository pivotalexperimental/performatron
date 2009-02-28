class Performatron::Sequence
  cattr_accessor :loaded_sequences
  cattr_accessor :verbose
  self.loaded_sequences = {}
  self.verbose = true

  attr_reader :name
  attr_reader :proc
  def initialize(name, options = {}, &block)
    @name = name.to_s
    @proc = block
    self.class.loaded_sequences[self.name] = self
  end

  def build
    Module.new()
  end

  def sanitized_name
    name.gsub(/\W+/, "_")
  end

  module Dsl
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
end