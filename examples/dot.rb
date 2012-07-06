require 'wongi-engine'

include Wongi::Engine

ds = Dataset.new
ds << rule('reflexive') {
  forall {
    has :P, "reflexive", true
    has :A, :P, :B
  }
  make {
    gen :B, :P, :A
  }
}

File.open "rete.dot", "w" do |io|
  Graph.new( ds ).dot( io )
end
