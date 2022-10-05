---
title: Queries
weight: 9
---

# Queries

Queries allow injecting variables at the top of a rule as a form of parametrization:

```ruby
q = engine.query "friends" do
  search_on :Name
  forall {
    has :Name, :friend, :Friend
  }
end

engine.execute "friends", Name: "Alice"
q.tokens.each do |token|
  # you know the drill
end
```
