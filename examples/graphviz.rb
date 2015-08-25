require 'wongi-engine'

include Wongi::Engine
include Wongi::Engine::DSL

ds = Network.new
ds << rule('demo') {
  forall {
    has 1, 2, 3
    maybe 4, 5, 6
  }
}

File.open "rete.dot", "w" do |io|
  Graph.new( ds ).dot( io )
end
