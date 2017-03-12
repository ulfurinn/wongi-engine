---
title: Taking an action
---

# Taking an action

There's more to rules than passive accumulation of results sets. Let's rewrite an earlier example as follows

```ruby
engine.rule "self-printer" do
  forall {
    has :A, :friend, :B
  }
  make {
    action { |token|
      puts "%s and %s are friends" % [ token[:A], token[:B] ]
    }
  }
end
```

The `make` section (aliased as `do!`) contains actions to be taken whenever the bottom of the matcher list if reached (we say "the production node is _activated_"). The simplest one is `action`, which simply runs the block with the resulting token.

Avoid modifying the engine inside action blocks (i.e., asserting and retracting facts and installing new rules). There are safer ways of doing this. Action blocks should only be used for side effects.
