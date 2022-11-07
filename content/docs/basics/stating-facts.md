---
title: Stating facts
weight: 2
---

# Stating facts

The rule engine requires _facts_ in order to reason about the world, and facts have to be positively _asserted_ for the engine to operate on.

All knowledge must be decomposed into triples, which are typically interpreted as `{subject, predicate, object}`. The _subject_ typically represents some entity about which we're reasoning. The _object_ is either another entity, or a primitive value. The _predicate_ is the relationship that connects the two.

Note that even if the subject represents an _entity_, you don't necessarily need to inject your literal domain model instance directly into the engine; if you want, you may freely use some stand-in value that can be mapped back to it, such as a database ID or a slug.

Any Ruby object that implements `#==` in a sensible way can be used in any position in a triple. The only exceptions are symbols that start with a capital latin letter or an underscore; they have special meaning in the engine.

In addition, it is recommended that predicates be expressed with symbols.

Though you are free to structure the triples in some other way than `{subject, predicate, object}`, your rules will likely be easier to read if you follow the convention, and the API will be more natural to use.

The roles of the terms are not fixed: a term that acts as a predicate in one fact can be a subject in another, allowing you to build meta-models, as you'll see in [a later example]({{<ref "more-facts.md">}}).

Try this:

```ruby
engine << ["Alice", :friend, "Bob"]
engine << ["Alice", :age, 35]
```

To remove facts, do:

```ruby
engine.retract ["Alice", :age, 35]
```

All facts exist independently of each other, and the engine makes no assumptions about their semantics. It makes sense for Alice to have more than one friend; having more than one _age_, however, is odd. This is something you need to keep in mind.

Now that we've taught the engine a little about the world, what can we do with it?
