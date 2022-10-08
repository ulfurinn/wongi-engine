require 'pry'
require 'wongi-engine'
require 'rspec/collection_matchers'

def print_dot_graph(engine, io = $stderr)
  Wongi::Engine::Graph.new(engine).dot(io)
end
