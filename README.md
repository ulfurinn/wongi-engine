# Wongi::Engine

This library contains a rule engine written in Ruby. It's based on the [Rete algorithm](http://en.wikipedia.org/wiki/Rete_algorithm) and uses a DSL to express rules in a readable way.

[![Build Status](https://travis-ci.org/ulfurinn/wongi-engine.svg?branch=master)](https://travis-ci.org/ulfurinn/wongi-engine) (MRI 1.9.3, 2.0, 2.1, 2.2, Rubinius, JRuby)

## Word of caution

This is complex and fragile machinery, and there may be subtle bugs that are only revealed with nontrivial usage. Be conservative with upgrades, test your rules extensively, and please report any behaviour that is not consistent with your expectations.

## How to use this thing?

[The tutorial](http://ulfurinn.github.io/wongi-engine/) should get you started nicely.

## Acknowledgements

The Rete implementation in this library largely follows the outline presented in [\[Doorenbos, 1995\]](http://reports-archive.adm.cs.cmu.edu/anon/1995/CMU-CS-95-113.pdf).

## Changelog

### 0.1.0

* massively rewritten rule activation; this simplifies development and debugging and opens the road for useful features such as fully reversible custom actions
* **treat this as a major upgrade and test thoroughly**

### 0.0.17

* introduced the `assuming` matcher

### 0.0.13

* fixed a bug with recursive generations of multiple facts

### 0.0.12

* fixed another NCC bug

### 0.0.11

* fixed cleanup of invalidated NCC branches

### 0.0.10

* fixed interaction of filters and optional nodes

### 0.0.9

* fixed the definition of `asserted` (#16)

### 0.0.8

* preventing the feedback loop introduced in 0.0.7; experimental

### 0.0.7

* added a guard against introducing variables in neg clauses
* fixed execution context of simple action block (#7)
* fixed #4 once more, better
* fixed a bug with OptionalNode (#12)
* fixed behaviour of neg nodes; this will cause feedback loops when a gen action creates a fact that invalidates the action's condition

### 0.0.6

* fixed a bug caused by retracting facts from within a rule action (#4)

### 0.0.5

* fixed a bug with multiple `assert` tests following the same node (#2)

### 0.0.4

* reintegrated RDF support
* collapsible filter matchers

### 0.0.3

* bug fixes
* `assert`, `assign`

### 0.0.1

* initial repackaged release

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
