---
title: Overlays
---

# Overlays

Overlays create scopes of facts. You can use them, for example, to quickly reset the engine to a pristine state, since compiling a large ruleset may be an expensive operation, and you may want to reuse the prepared engine between several independent sets of data.

```ruby
engine.with_overlay do |overlay|
  # overlay << [x, y, z]
  # overlay.retract [x, y, z]
end

# the engine state is reset here
```

Overlays may be nested if necessary, creating nested scopes. Facts in the outer overlay are visible in inner overlays.
