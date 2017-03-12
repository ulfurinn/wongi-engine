---
title: More facts!
---

# More facts!

Note how our facts define relations that always go from subject to object, i.e., they describe a directed graph. In a perfect world, friendships would go both ways, i.e. the friendship relation would be symmetric. To model that, we would have to manually assert `[:a, :friend, :b]` and `[:b, :friend, :a]`, or we can make the engine do the work:

```ruby
engine.rule "symmetric predicate" do
  forall {
    has :P, :symmetric, true
    has :X, :P, :Y
  }
  make {
    gen :Y, :P, :X
  }
end

engine << [:friend, :symmetric, true]
```

If you do this on the engine with the self-printer rule installed, you'll instantly see the new reciprocated friendships pop up.

`gen` is an action that creates new facts based on the provided template and the variables bound in the token, and it's one of the most important elements in a rule. Generated actions can trigger other rules, which is a very powerful mechanism.
