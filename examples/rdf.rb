require 'wongi-rdf'
require 'wongi-engine'

engine = Wongi::Engine.create
engine.rdf!
parser = Wongi::RDF::Parser.new
parser.parse_file File.expand_path( "rdf.n3", File.dirname(__FILE__) ), engine

engine.each do |wme|
  puts wme
end

serializer = Wongi::RDF::Serializer.new engine
puts serializer.serialize
