require 'wongi-engine'

def sep
  puts "---------------------------"
end

engine = Wongi::Engine.create

engine.debug!

engine.compile_alpha Wongi::Engine::Template.new( :_, :_, :_,  0 )
engine.compile_alpha Wongi::Engine::Template.new( :_, :_, :_, -1 )
engine.compile_alpha Wongi::Engine::Template.new( :_, :_, :_, -2 )
engine.compile_alpha Wongi::Engine::Template.new( :_, :_, :_, -3 )
engine.compile_alpha Wongi::Engine::Template.new( :_, :_, :_, -4 )
engine.compile_alpha Wongi::Engine::Template.new( :_, :_, :_, -5 )

engine.full_wme_dump

sep

engine << [1, 1, 1]
engine.full_wme_dump
engine.snapshot!

sep

engine << [2, 2, 2]
engine.full_wme_dump
engine.snapshot!

sep

engine << [3, 3, 3]
engine.full_wme_dump
engine.snapshot!

sep

engine << [4, 4, 4]
engine.full_wme_dump
engine.snapshot!

sep

engine << [5, 5, 5]
engine.full_wme_dump
engine.snapshot!
