# Wongi::Engine

This library provides a rule engine for applications written in Ruby.
It contains an implementation of the [Rete algorithm](http://en.wikipedia.org/wiki/Rete_algorithm), which largely follows the outline presented in [\[Doorenbos, 1995\]](http://reports-archive.adm.cs.cmu.edu/anon/1995/CMU-CS-95-113.pdf), and a DSL for expressing rules in a readable way.

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

All knowledge in Wongi::Engine is represented as triples of { subject, predicate, object }. Predicates usually stand for subjects' properties, and objects for values of those properties. More complex types can always be decomposed into such triples.

Triples can contain any Ruby object that defines the `==` comparison in a meaningful way, but some symbols have special meaning, as we will see.

Try this:

	engine << [ "Alice", "friend", "Bob" ]
	engine << [ "Alice, "age", 35 ]

What can we do with this information?

### Simple iteration

Suppose we want to list all we know about Alice. You could, for instance, do:

	engine.each "Alice", :_, :_ do |item|
		puts "Alice's #{item.predicate} is #{item.object}"
	end

`each` takes three arguments for every field of a triple and tries to match the resulting template against the known facts. `:_` is the special value that matches anything. This kind of pattern matching plays a large role in Wongi::Engine; more on that later.

In a similar way, you can use `select` to get an array of matching facts and `find` to get the first matching one. Both methods take three arguments.

### Simple rules

It's not very interesting to use the engine like that, though. Rule engines are supposed to be declarative. Let's try this:

	friends = engine.rule "friends" do
		forall {
			has :PersonA, "friend", :PersonB
		}
	end

Here's your first taste of the engine's DSL. A rule, generally speaking, consists of a number of conditions the dataset needs to meet; those are defined in the `forall` section (also spelled `for_all`, if you prefer that). `has` (or `fact`) specifies that there needs to be a fact that matches the given pattern; in this case, one with the predicate `"friends"`.

When a pattern contains a symbol that starts with an uppercase letter, it introduces a variable which will be bound to an actual triple field. Their values can be retrieved from the result set:

	friends.tokens.each do |token|
		puts "%s and %s are friends" % [ token[ :PersonA ], token[ :PersonB ] ]
	end

A **token** represents all facts that passed the rule's conditions. If you think of the dataset as of a long SQL table being joined with itself, then a token is like a row in the resulting table.

If you don't care about a specific field's value, you can use the all-matcher `:_` in its place so as not to introduce unnecessary variables.

Once a variable is bound, it can be used to match further facts within a rule. Let's add another friendship:

	engine << [ "Bob", "friend", "Claire" ]

and another rule:
	
	remote = engine.rule "remote friends" do
		forall {
			has :PersonA, "friend", :PersonB
			has :PersonB, "friend", :PersonC
		}
	end

	remote.tokens.each do |token|
		puts "%s and %s are friends through %s" % [ token[ :PersonA ], token[ :PersonC ], token[ :PersonB ] ]
	end

(`engine.rule` returns the created **production node** - an object that accumulates the rule's result set. You don't have to carry it around if you don't want to - it is always possible to retrieve it later as `engine.productions["remote friends"]`.)

### Stored queries

Taking the SQL metaphor further, you can use the engine to do fancy searches:

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

Not that this is a particularly fancy search, but you get the idea.

Queries work the same way as normal rules, but they come with some variables already bound by the time matching starts.

You can also retrieve the query's production node from `engine.results["friends"]` (they are intentionally kept separate from regular productions).

### Taking an action

There's more to rules than passive accumulation:

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

The `make` section (also spelled `do!`, if you find it more agreeable English, because `do` is a keyword in Ruby) lists everything that happens when a rule's condition are fully matched (we say the production node is activated). Wongi::Engine provides only a small amount of build-in actions, but you can define define your own ones, and the simplest one is just `action` with a block.

### More facts!

Note how our facts define relations that always go from subject to object - they form a directed graph. In a perfect world, friendships go both ways, but to specify this in out model, we need to have two facts for each couple. Instead of duplicating everything by hand, let's automate that:

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

If you still have the "self-printer" rule installed, you will see some new friendships pop up!

The built-in `gen` action creates new facts, taking either fixed values or variables as arguments. (It will complain if use provide a variable that isn't bound by the time it's activated.) Here, it takes all relations we've defined to be [symmetric](http://en.wikipedia.org/wiki/Symmetric_relation), finds all couples in those sorts of relations and turns them around.

### Matchers

It wouldn't be very useful if `has` were the only sort of condition that could be used. Here are some more:

#### `neg subject, predicate, object`

Passes if the specified template does *not* match anything in the dataset. Alias: `missing`.

#### `maybe subject, predicate, object`

Passes whether or not the template matches anything. It's only useful if it introduces a new variable. Alias: `optional`.

#### `none { ... }`

The `none` block contains other matchers and passes if that *entire subchain* returns an empty set. In other words, it corresponds to an expression `not ( a and b and ... )`.

#### `any { variant { ... } ... }`

The `any` block contains several `variant` blocks, each of them containing other matchers. It passes if any of the `variant` subchains matches. It's a shame that disjunction has to be so much more verbose than conjunction, but life is cruel.

#### `same x, y`

Passes if the arguments are equal. Alias: `eq`, `equal`.

#### `diff x, y`

Passes if the arguments are not equal. Alias: `ne`.

### Timeline

Wongi::Engine has a limited concept of timed facts: time is discrete and only extends into the past. Matchers that accept a triple specification (`has`, `neg` and `maybe`) can also accept a fourth parameter, an integer <= 0, which will make them look at a past state of the system. "0" means the current state and is the default value, "-1" means the one just before the current, and so on.

To create past states, say:

	engine.snapshot!

This will shift all facts one step into the past. The new current state will be a copy of the last one. You can only insert new facts into the current state, "retroactive" facts are not allowed.

### Time-aware matchers

The following matchers are nothing but syntactic sugar for a combination of primitives.

#### `asserted subject, predicate, object`

Short for:
	
	neg subject, predicate, object, -1
	has subject, predicate, object, 0

That is, it passes if the fact was missing in the previous state but exists in the current one. Alias: `added`.

#### `retracted subject, predicate, object`

Short for:

	has subject, predicate, object, -1
	neg subject, predicate, object, 0

The reverse of `asserted`. Alias: `removed`.

#### `kept subject, predicate, object`

Short for:

	has subject, predicate, object, -1
	has subject, predicate, object, 0

Alias: `still_has`.

#### `kept_missing subject, predicate, object`

Short for:

	neg subject, predicate, object, -1
	neg subject, predicate, object, 0

Alias: `still_missing`.

### Custom actions

TODO

#### Custom matchers

### Organising rules

To make rules and queries more manageable, you will probably want to keep them separate from the engine instance. One way to do that is to just say:

	my_rule = rule "name" do
		...
	end

	engine << my_rule

For even more convenience, why not group rules together:

	my_ruleset = ruleset {
		rule "rule 1" do
			...
		end
		rule "rule 2" do
			...
		end
	}

	engine << my_ruleset

Again, you don't need to hold on to object references if you don't want to:

	ruleset "my set" do
		...
	end

	engine << Wongi::Engine::Ruleset[ "my set" ]

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
