---
title: Overlays
weight: 9
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

Overlays may be nested if necessary, creating nested scopes, kind of like layered filesystems.

{{<hint "info">}}Only the current (top-most) overlay may be modified. Lower ones may be modified once everything on top of them goes out of scope.{{</hint>}}

{{<hint "warning">}}[Entity iterators]({{<ref "known-knowns.md#entity-iterators">}}) created inside an overlay are only guaranteed to be valid while that overlay is the current one.{{</hint>}}