---
title: Simple iteration
---

# Simple iteration

Suppose we wanted to find everything we know about Alice. To do this, try:

```ruby
engine.each("Alice", :_, :_) do |elem|
  puts "Alice's #{elem.predicate} is #{elem.object}"
end
```

`#each` takes a _pattern_ and iterates over all known facts matching that pattern. `:_` here is a wildcard that matches anything.

In a similar fashion, `#select` returns an array of all matching facts, and `#find` returns the first matching one.
