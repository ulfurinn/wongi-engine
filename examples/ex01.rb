include Wongi::Engine

ds = Network.new

ds << WME.new( "Alice", "friend", "Bob" )

puts "Enumerate all:"

ds.each do |wme|
  puts wme
end

puts "Enumerate by pattern:"

ds.each nil, "friend", nil do |wme|
  puts wme
end

puts "Mismatching pattern:"

ds.each nil, "foe", nil do |wme|
  puts wme
end
