include Wongi::Engine

ds = Network.new

ds << ruleset {

  name "Example"

  rule "symmetric" do
    forall {
      has :P, "symmetric", true
      has :A, :P, :B
    }
    make {
      gen :B, :P, :A
    }
  end

}

puts "Installed ruleset"

ds << WME.new( "friend", "symmetric", true )
ds << WME.new( "Alice", "friend", "Bob" )

puts "Asserted facts:"

puts "Should print 3 facts:"
puts ds.wmes


ds.retract WME.new( "Alice", "friend", "Bob" )

puts "Should print 1 fact:"
puts ds.wmes

