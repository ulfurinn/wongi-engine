engine = Wongi::Engine.create

engine << ["Alice", "friend", "Bob"]

puts "Enumerate all:"

engine.each do |wme|
  puts wme
end

puts "Enumerate by pattern:"

engine.each :_, "friend", :_ do |wme|
  puts wme
end

puts "Mismatching pattern:"

engine.each :_, "foe", :_ do |wme|
  puts wme
end
