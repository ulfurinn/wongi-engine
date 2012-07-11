include Wongi::Engine

ds = Network.new

ds << ruleset {

  name "Example"

  rule "reflexive" do
    forall {
      has :P, "reflexive", true
      has :A, :P, :B
    }
    make {
      gen :B, :P, :A
    }
  end

}

puts "Installed ruleset"

ds << WME.new( "friend", "reflexive", true )
ds << WME.new( "Alice", "friend", "Bob" )

puts "Asserted facts"

puts ds.wmes

puts "Should output 3 facts"

ds.retract WME.new( "Alice", "friend", "Bob" )

puts ds.wmes

puts "Should output 1 fact"
