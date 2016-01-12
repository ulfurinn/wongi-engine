# Changelog

## 0.2.6

* fixed `Network#each`

## 0.2.5

* fixed some overlay-related memory leaks

## 0.2.3

* fixed the error collector

## 0.2.2

* fixed retention of WMEs added to an overlay

## 0.2.1

* data overlay fixes

## 0.2.0

* refactored compilation code
* [data overlays](https://github.com/ulfurinn/wongi-engine/issues/45)
* DSL methods are removed from `Object` and are available by including `Wongi::Engine::DSL` instead

## 0.1.4

* fixed a bug in evaluation of `assign` nodes

## 0.1.0

* massively rewritten rule activation; this simplifies development and debugging and opens the road for useful features such as fully reversible custom actions
* **treat this as a major upgrade and test thoroughly**

## 0.0.17

* introduced the `assuming` matcher

## 0.0.13

* fixed a bug with recursive generations of multiple facts

## 0.0.12

* fixed another NCC bug

## 0.0.11

* fixed cleanup of invalidated NCC branches

## 0.0.10

* fixed interaction of filters and optional nodes

## 0.0.9

* fixed the definition of `asserted` (#16)

## 0.0.8

* preventing the feedback loop introduced in 0.0.7; experimental

## 0.0.7

* added a guard against introducing variables in neg clauses
* fixed execution context of simple action block (#7)
* fixed #4 once more, better
* fixed a bug with OptionalNode (#12)
* fixed behaviour of neg nodes; this will cause feedback loops when a gen action creates a fact that invalidates the action's condition

## 0.0.6

* fixed a bug caused by retracting facts from within a rule action (#4)

## 0.0.5

* fixed a bug with multiple `assert` tests following the same node (#2)

## 0.0.4

* reintegrated RDF support
* collapsible filter matchers

## 0.0.3

* bug fixes
* `assert`, `assign`

## 0.0.1

* initial repackaged release
