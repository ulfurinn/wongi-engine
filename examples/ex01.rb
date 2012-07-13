include Wongi::Engine

ds = Network.new

ds << WME.new( "Alice", "friend", "Bob" )

puts "Enumerate all:"

ds.each do |wme|
  puts wme
end

puts "Enumerate by pattern:"

ds.each :_, "friend", :_ do |wme|
  puts wme
end

puts "Mismatching pattern:"

ds.each :_, "foe", :_ do |wme|
  puts wme
end
