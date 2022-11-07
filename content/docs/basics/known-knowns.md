---
title: Known knowns
weight: 3
---

# Known knowns

Suppose we wanted to list everything we know about Alice. To do this, try:

```ruby
engine.each("Alice", :_, :_) do |elem|
  puts "Alice's #{elem.predicate} is #{elem.object}"
end
```

`#each` takes a _pattern_ and iterates over all known facts matching that pattern. `:_` here is a wildcard that matches anything.

You can also call `#each` with a single three-element array argument, or with no arguments at all, in which case it will iterate over the entire fact set.

`#find` is similar, but it returns the first matching fact.

## Entity iterators

Walking the facts directly can be a bit verbose. If a lot of your lookups use a pattern like `{x, _, _}`, entity iterators are more convenient.

Try:

```ruby
alice = engine.entity("Alice")
```

This gives you access to the following:

### `#each`

```ruby
alice.each do |predicate, object|
  puts "Alice's #{predicate} is #{object}"
end
```

`#each` returns a standard `Enumerator`, so you can do all normal enumeratory things with it. Be wary of calling `#to_h` on it though: it is possible to have several objects for the same predicate. If Alice has more than one friend, the _last_ matching one will be included in the returned hash. This will be inconsistent with other accessors, which will return the _first_ matching one.

### `#get` / `#[]`

```ruby
puts "Alice's friend is #{alice.get(:friend)}"
```

`#get` returns `nil` if no matching predicate exists.

### `#get_all`

```ruby
puts "Alice's friends are #{alice.get_all(:friend).join(", ")}"
```

### `#fetch`

```ruby
puts "Alice's friend is #{alice.fetch(:friend)}"
```

This has the same interface as `Hash#fetch`: it accepts a default value or a block, and raises a `KeyError` if no matching facts exist and no defaults are given.

### `#method_missing` and `#respond_to?`

The predicate needs to be a symbol for this to work, as is generally recommended.

```ruby
puts "Alice's friend is #{alice.friend}" if alice.respond_to?(:friend)
```

This raises a `NoMethodError` if no matching facts exist.