---
title: Timelines
---

# Timelines

`Wongi::Engine` has a limited concept of timed facts: time is discrete and only extends into the past. Matchers that accept a triple specification (`has`, `neg`, `maybe`) can also accept a time option, an integer <= 0, which will make them look at a past state of the system. "0" means the current state and is the default value, "-1" means the one just before the current, and so on.

To create past states, say:

```ruby
engine.snapshot!
```

This will shift all facts one step into the past. The new current state will be a copy of the last one. You can only insert new facts into the current state, "retroactive" facts are not allowed.

## Time-aware matchers

The following matchers are nothing but syntactic sugar for a combination of primitives.

### asserted / added

```ruby
asserted x, y, z
```

Short for:

```ruby
has x, y, z, time: 0
neg x, y, z, time: -1
```

That is, it passes if the fact was missing in the previous state but exists in the current one.

### retracted / removed

Short for:

```ruby
has x, y, z, time: -1
neg x, y, z, time: 0
```

The reverse of asserted.

# kept / still_has

Short for:

```ruby
has x, y, z, time: -1
has x, y, z, time: 0
```

# kept_missing / still_missing

Short for:

```ruby
neg x, y, z, time: -1
neg x, y, z, time: 0
```

Since `neg` rules cannot introduce new variables, neither can this one.
