---
title: Rulesets
weight: 10
---

# Rulesets

Rulesets allow grouping related rules together and installing them in one go:

```ruby
my_ruleset = ruleset "my ruleset" do
  rule "rule 1" do
    # ...
  end

  rule "rule 2" do
    # ...
  end
end

engine << my_ruleset
# or
engine << Wongi::Engine::Ruleset["my ruleset"]
```
