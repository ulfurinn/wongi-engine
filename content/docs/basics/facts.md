---
title: Facts
weight: 2
---

# Facts

The rule engine requires _facts_ in order to reason about the world, and facts have to be positively _asserted_ for the engine to operate on.

All knowledge must be decomposed into triples, which are typically interpreted as `{subject, predicate, object}`. The terms called `subject` and `object` are two entities or values about which we know something, and `predicate` is some kind of relationship between them. Though you are free to structure the triples in another way, your rules will likely be easier to read if you follow the convention.

The roles of the terms are not fixed: a term that acts as a predicate in one fact can be a subject in another, allowing you to build meta-models, as you'll see in [a later example](../more-facts).

Try this:

```ruby
engine << ["Alice", :friend, "Bob"]
engine << ["Alice", :age, 35]
```

To remove facts, do:

```ruby
engine.retract ["Alice", :age, 35]
```

Any Ruby object that implements `#==` in a sensible way can be used in any position in a triple. The only exceptions are symbols that start with a capital latin letter or an underscore; they have special meanings in the engine.

In addition, it is recommended that predicates be expressed with symbols.

Now that we've taught the engine a little about the world, what can we do with it?
