# Wongi::Engine

This library contains a rule engine written in Ruby. It's based on the [Rete algorithm](http://en.wikipedia.org/wiki/Rete_algorithm) and uses a DSL to express rules in a readable way.

## Installation

Add this line to your application's Gemfile:

    gem 'wongi-engine'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wongi-engine

## Tutorial

To begin, say

	engine = Wongi::Engine.create

Now let's add some facts to the system.

### Facts

All knowledge in Wongi::Engine is represented by triples of { subject, predicate, object }. Predicates usually stand for subjects' properties, and objects for values of those properties. More complex types can always be decomposed into such triples.

Triples can contain any Ruby object that defines the `==` comparison in a meaningful way, but some symbols have special meaning, as we will see.

Try this:

```ruby
engine << [ "Alice", "friend", "Bob" ]
engine << [ "Alice", "age", 35 ]
```

What can we do with this information?

### Simple iteration

Suppose we want to list all we know about Alice. You could, for instance, do:

```ruby
engine.each "Alice", :_, :_ do |item|
	puts "Alice's #{item.predicate} is #{item.object}"
end
```

`each` takes three arguments for every field of a triple and tries to match the resulting template against the known facts. `:_` is the special value that matches anything. This kind of pattern matching plays a large role in Wongi::Engine; more on that later.

In a similar way, you can use `select` to get an array of matching facts and `find` to get the first matching one. Both methods take three arguments.

### Simple rules

It's not very interesting to use the engine like that, though. Rule engines are supposed to be declarative. Let's try this:

```ruby
friends = engine.rule "friends" do
	forall {
		has :PersonA, "friend", :PersonB
	}
end
```

Here's your first taste of the engine's DSL. A rule, generally speaking, consists of a number of conditions the dataset needs to meet; those are defined in the `forall` section (also spelled `for_all`, if you prefer that). `has` (or `fact`) specifies that there needs to be a fact that matches the given pattern; in this case, one with the predicate `"friends"`.

When a pattern contains a symbol that starts with an uppercase letter, it introduces a variable which will be bound to an actual triple field. Their values can be retrieved from the result set:

```ruby
friends.tokens.each do |token|
	puts "%s and %s are friends" % [ token[ :PersonA ], token[ :PersonB ] ]
end
```

A **token** represents all facts that passed the rule's conditions. If you think of the dataset as of a long SQL table being joined with itself, then a token is like a row in the resulting table.

If you don't care about a specific field's value, you can use the all-matcher `:_` in its place so as not to introduce unnecessary variables.

Once a variable is bound, it can be used to match further facts within a rule. Let's add another friendship:

```ruby
engine << [ "Bob", "friend", "Claire" ]
```

and another rule:
	
```ruby
remote = engine.rule "remote friends" do
	forall {
		has :PersonA, "friend", :PersonB
		has :PersonB, "friend", :PersonC
	}
end

remote.tokens.each do |token|
	puts "%s and %s are friends through %s" % [ token[ :PersonA ], token[ :PersonC ], token[ :PersonB ] ]
end
```

(`engine.rule` returns the created **production node** - an object that accumulates the rule's result set. You don't have to carry it around if you don't want to - it is always possible to retrieve it later as `engine.productions["remote friends"]`.)

### Stored queries

Taking the SQL metaphor further, you can use the engine to do fancy searches:

```ruby
q = engine.query "friends" do
	search_on :Name
	forall {
		has :Name, "friend", :Friend
	}
end

engine.execute "friends", { Name: "Alice" }
q.tokens.each do |token|
	... # you know the drill
end
```

Not that this is a particularly fancy search, but you get the idea.

Queries work the same way as normal rules, but they come with some variables already bound by the time matching starts.

You can also retrieve the query's production node from `engine.results["friends"]` (they are intentionally kept separate from regular productions).

### Taking an action

There's more to rules than passive accumulation:

```ruby
engine.rule "self-printer" do
	forall {
		has :PersonA, "friend", :PersonB
	}
	make {
		action { |token|
			puts "%s and %s are friends" % [ token[ :PersonA ], token[ :PersonB ] ]
		}
	}
end
```

The `make` section (also spelled `do!`, if you find it more agreeable English, because `do` is a keyword in Ruby) lists everything that happens when a rule's conditions are fully matched (we say "the production node is **activated**"). Wongi::Engine provides only a small amount of built-in actions, but you can define your own ones, and the simplest one is just `action` with a block.

### More facts!

Note how our facts define relations that always go from subject to object - they form a directed graph. In a perfect world, friendships go both ways, but to specify this in out model, we need to have two facts for each couple. Instead of duplicating everything by hand, let's automate that:

```ruby
engine.rule "symmetric predicate" do
	forall {
		has :Predicate, "symmetric", true
		has :X, :Predicate, :Y
	}
	make {
		gen :Y, :Predicate, :X
	}
end

engine << ["friend", "symmetric", true]
```

If you still have the "self-printer" rule installed, you will see some new friendships pop up immediately!

The built-in `gen` action creates new facts, taking either fixed values or variables as arguments. (It will complain if you provide a variable that isn't bound by the time it's activated.) Here, it takes all relations we've defined to be [symmetric](http://en.wikipedia.org/wiki/Symmetric_relation), finds all couples in those sorts of relations and turns them around.

### Matchers

It wouldn't be very useful if `has` were the only sort of condition that could be used. Here are some more:

#### `neg subject, predicate, object`

Passes if the specified template does *not* match anything in the dataset. Alias: `missing`.

#### `maybe subject, predicate, object`

Passes whether or not the template matches anything. It's only useful if it introduces a new variable; you can think of `LEFT JOIN`. Alias: `optional`.

#### `none { ... }`

The `none` block contains other matchers and passes if that *entire subchain* returns an empty set. In other words, it corresponds to an expression `not ( a and b and ... )`.

#### `any { option { ... } ... }`

The `any` block contains several `option` blocks, each of them containing other matchers. It passes if any of the `option` subchains matches. It's a shame that disjunction has to be so much more verbose than conjunction, but life is cruel.

#### `same x, y`

Passes if the arguments are equal. Alias: `eq`, `equal`.

#### `diff x, y`

Passes if the arguments are not equal. Alias: `ne`.

#### `assert { |token| ... }`, `assert var1, var2, ... do |val1, val2, ... | ... end`

Passes if the block evaluates to `true`. Having no arguments passes the entire token as an argument, listing some variables passes only their values.

#### `assign variable do |token| ... end`

Not a *matcher*, strictly speaking, because it always passes. What it does instead is introduce a new variable bound to the block's return value.

### Timeline

Wongi::Engine has a limited concept of timed facts: time is discrete and only extends into the past. Matchers that accept a triple specification (`has`, `neg` and `maybe`) can also accept a fourth parameter, an integer <= 0, which will make them look at a past state of the system. "0" means the current state and is the default value, "-1" means the one just before the current, and so on.

To create past states, say:

```ruby
engine.snapshot!
```

This will shift all facts one step into the past. The new current state will be a copy of the last one. You can only insert new facts into the current state, "retroactive" facts are not allowed.

### Time-aware matchers

The following matchers are nothing but syntactic sugar for a combination of primitives.

#### `asserted subject, predicate, object`

Short for:
	
```ruby
neg subject, predicate, object, -1
has subject, predicate, object, 0
```

That is, it passes if the fact was missing in the previous state but exists in the current one. Alias: `added`.

#### `retracted subject, predicate, object`

Short for:

```ruby
has subject, predicate, object, -1
neg subject, predicate, object, 0
```

The reverse of `asserted`. Alias: `removed`.

#### `kept subject, predicate, object`

Short for:

```ruby
has subject, predicate, object, -1
has subject, predicate, object, 0
```

Alias: `still_has`.

#### `kept_missing subject, predicate, object`

Short for:

```ruby
neg subject, predicate, object, -1
neg subject, predicate, object, 0
```

Alias: `still_missing`.

### Other built-in actions

#### `collect variable, collector_name`

If you use this action, `engine.collection( collector_name )` will provide a `uniq`'ed array of all values `variable` has been bound to. It's a bit shorter than iterating over the tokens by hand.

#### `error message`, `error { |hash_of_variable_assignments| ... }`

Useful when you want to detect contradictory facts. `engine.errors` will give an array of all error messages produced when this action is activated. If you use the block form, the block needs to return a message.

#### `trace options`

The debugging action that will print a message every time it's activated. Possible options are:

* `values` (boolean = false): whether to print variable assignments as well
* `io` (IO = $stdout): which IO object to use
* `generation` (boolean = false): whether this rule's `gen` action should print messages too. `trace` must come before any `gen` actions in this case.
* `tracer`, `tracer_class`: a custom tracer that must respond to `trace` and accept a hash argument. Hash contents will vary depending on the action being traced.

### Custom actions

We've seen one way to specify custom actions: using `action` with a block. Another way to use it is to say:

```ruby
action class, ... do
	...
end
```

Any additional arguments or blocks will be given to `initialize`, and the class must define an `execute` method taking a token. Passing any object with an `execute` method also works.

If your action class inherits from `Wongi::Engine::Action`, you'll have the following (more or less useful) attributes:

* `rete`: the engine instance
* `rule`: the rule object that is using this action
* `name`: the extension clause used to define this action (read more under [DSL extensions](#dsl-extensions))
* `production`: the production node

If you can't or don't want to inherit, you can define the accessors yourself. Having just the ones you need is fine.

### Organising rules

Using `engine.rule` and `engine.query` is fine if you want to experiment, but to make rules and queries more manageable, you will probably want to keep them separate from the engine instance. One way to do that is to just say:

```ruby
my_rule = rule "name" do
	...
end

engine << my_rule
```

For even more convenience, why not group rules together:

```ruby
my_ruleset = ruleset {
	rule "rule 1" do
		...
	end
	rule "rule 2" do
		...
	end
}

engine << my_ruleset
```

Again, you don't need to hold on to object references if you don't want to:

```ruby
ruleset "my set" do
	...
end

engine << Wongi::Engine::Ruleset[ "my set" ]
```

### DSL extensions

This is a more advanced method of customising. In general, DSL extensions have the form:

```ruby
dsl {
	section [ :forall | :make ]
	clause :my_action
	[ action | accept | body ] ...
}
```

which is then used in a rule like this:

```ruby
make {
	my_action ...
}
```

DSL extensions are globally visible to all engine instances.

Let's have a look at the three ways to define a clause's implementation.

#### `body { |...| ... }`

This simply allows you to group several other actions or matchers. It is perhaps the only way you have to extend the `forall` section, as any non-trivial matchers will require special support from the engine itself.

#### `action class`, `action do |token| ... end`

This works almost exactly like using the `action` action directly in a rule, but gives it a more meaningful alias. Arguments to `initialize`, however, are taken from the action's invocation in `make`, not the definition.

A useful pattern is having specialised named collectors, defined like this:

```ruby
dsl {
	section :make
	clause :my_collection
	action Wongi::Engine::SimpleCollector.collector
}
```

installed like this:

```ruby
rule('collecting') {
	...
	make {
		my_collection :X
	}
}
```

and accessed like this:

```ruby
collection = engine.collection :my_collection
```

#### `accept class`

Most library users probably won't need this, but it's here for completion. Acceptors represent an intermediate state. They allow you to have some shared data that you customize for a given engine instance. The class needs to respond to `import_into( engine_instance )` and return something usable as an action, or to be usable as an action itself.

The class also gets arguments to `initialize` from the action's invocation.

## Acknowledgements

The Rete implementation in this library largely follows the outline presented in [\[Doorenbos, 1995\]](http://reports-archive.adm.cs.cmu.edu/anon/1995/CMU-CS-95-113.pdf).

## Changelog

### 0.0.1

* initial repackaged release

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
