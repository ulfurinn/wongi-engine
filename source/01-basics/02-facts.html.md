---
title: Facts
---

# Facts

All knowledge is represented with triples of `{subject, predicate, object}`, where `subject` and `object` are two entities and `predicate` is the kind of relationship between them.
Any kind of complex structures and relationships between entities can be decomposed into a set of such triples.

Try this:

```ruby
engine << ["Alice", :friend, "Bob"]
engine << ["Alice", :age, 35]
```

To remove facts, do:

```ruby
engine.retract ["Alice", :age, 35]
```

There are no restrictions on what constitutes a subject vs a predicate. A term that is used as a predicate in one triple can be a predicate in another, allowing you to build meta-models of your data.

Any Ruby object that implements `#==` in a sensible way can be used in any position in a triple, except symbols that start with an uppercase latin letter and `:_`, which have special meaning; more on those later. Uppercase symbols were chosen because you never see them in idiomatic Ruby code, so they're fair game for overloading.

For performance reasons, it is recommended to use symbols over strings whenever possible since the engine performs a lot of comparisons. Predicates in particular should always be expressed with symbols.

Now, what can we do with this information?
