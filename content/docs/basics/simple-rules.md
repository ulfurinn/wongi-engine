---
title: Simple rules
weight: 4
---

# Simple rules

This is not a very interesting way to use a rule engine, though. It's supposed to do the searching and matching part for you.

Let's try this:

```ruby
friends = engine.rule "friends" do
  forall {
    has :A, :friend, :B
  }
end
```

This is the most basic kind of rule. A rule needs to have a `forall` section, describing the conditions for the rule. The conditions will be composed of a number of _matchers_, like `has` in this example. Matchers will be triggered sequentially top to bottom, and the rule will _activate_ when they all pass successfully.

In this example we're matching against all facts that say someone is someone else's friend. The predicate of the matcher is `:friend`, which will match any fact with the same literal predicate. The subject and the object, however, are special. Symbols starting with capital letters are interpreted as _variables_. The first time a variable is encountered, it is _bound_ to the corresponding element of the matching fact.

`:_` is available as a placeholder for values you don't care about and don't want to waste a variable on.

An easy way to investigate what own rule found is this:

```ruby
friends.tokens.each do |token|
  puts "%s and %s are friends" % [ token[:A], token[:B] ]
end
```

Tokens are built up as execution flows through all the matchers, collecting all the encountered variables.

We can do more with variables. When you use a previously bound variable, its value will be used instead. Let's add another fact:

```ruby
engine << ["Bob", :friend, "Claire"]
```

and another rule:

```ruby
second_degree = engine.rule "friends of friends" do
  forall {
    has :A, :friend, :B
    has :B, :friend, :C
  }
end

second_degree.tokens.each do |token|
  puts "%s and %s are friends through %s" % [ token[:A], token[:C], token[:B] ]
end
```

(The object returned by `engine#rule` is called the production node. You don't need to carry it around — you can always access it as `engine.productions["friends of friends"]`. In fact, you shouldn't even need to use it that often, as there are more powerful ways to work with result sets.)
