---
title: DSL extensions
---

# DSL extensions

You can define your own elements in the rule DSL; the built-in ones are themselves defined through this mechanism. Defining custom matchers is difficult, since they generally rely on special support from the engine core (filter matchers being an exception), but custom actions could improve the readability of your rules.

The basic form for an extension is:

```ruby
dsl {
  section [ :forall | :make ]
  clause :my_action

  # one of the following:

  body {
    # ...
  }

  action class
  action { |token|
    # ...
  }

  accept class

}
```

`body` needs to contain other matchers or actions; it is essentially an alias for a commonly reused group.

`action` works the same way as the built-in `action` clause, but gives it a meaningful name, which may improve readability.

For example, this is how you can define custom collectors:

```ruby
dsl {
  section :make
  clause :my_collection
  action Wongi::Engine::SimpleCollector.collector
}

rule {
  # ...
  make {
    my_collection :X
  }
}

collection = engine.collection :my_collection
```

`accept` defines an intermediate state in rule compilation; the class needs to define `#import_into(engine)`, which needs to return an object conforming to the action interface.
