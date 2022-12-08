---
title: Matchers
weight: 2
---

# Matchers

This section describes all the matchers currently recognized by the `forall` section.

## has

```ruby
has x, y, z
```

`has` passes when it finds a fact that matches the template. It can introduce new variables.

## neg / missing

```ruby
neg x, y, z
```

`neg` passes when it _cannot_ find any facts that match the template. It **may not** introduce new variables (because it doesn't make say to say "let x equal something that doesn't exist").

## maybe / optional

```ruby
maybe x, y, z
```

`maybe` passes whether or not it finds a fact that matches the template. It is only useful if it introduces a new variable.

## none / ncc

```ruby
none {
  has x, y, z
  # ...
}
```

`none` creates a subchain of matchers and passes if that entire subchain yields an empty result set.

## any

```ruby
any {
  option {
    has x, y, z
    # ...
  }
  option {
    has x, y, z
    # ...
  }
}
```

`any` passes if any of the subchains in `option`s yield a non-empty result set.

## assign

```ruby
assign :X do |token|
   # ...
end
```

`assign` always passes. The argument must be a new variable that will be bound to the value returned by the block.

## assuming

```ruby
engine << rule("base") do
  # ...
end

engine << rule("specialization") do
  forall {
    assuming "base"
    # ...
  }
end
```

If several of your rules have a common prefix, `assuming` lets you extract it into a reusable base rule. The specialized rule will work as if the `forall` section of the base rule were included verbatim. This lets you keep your rules more compact and helps performance a bit, since some of the work can be reused.

The base rule must be installed prior to installing the specialized ones.

The rule compiler can collapse some simpler matchers like `has` into a single execution node if it detects that the declarations are identical, but for matchers taking code blocks, like `assert`, it is not possible, and `assuming` must be used.

## Filters

Filters are a category of matchers that block rule execution based on some predicate; they operate entirely on the token assembed so far.

Any argument to filter clauses can be a variable or a literal value, though usually you'd want at least one argument to be a variable.

### same / eq / equal

```ruby
same x, y
```

`same` passes if its arguments compare as equal using `#==`. It's recommended to only use it if _both_ arguments are variables, because otherwise you can usually just match on the expected value directly with `has`.

### diff / ne

```ruby
diff x, y
```

`diff` passes if its arguments do not compare as equal using `#==`.

As with `same`, it's best to use this matcher when both arguments are variables. However, note that there is a subtle difference in behaviour between "there is no value X" and "there is a value that is not X". To illustrate, suppose you have an item that is tagged with `luxury` and `import`, and you encode this with `{item, tag, luxury}` and `{item, tag, import}`.

Then, you might want to have a rule that captures non-imported items, so you can try saying:

```ruby
forall {
  has :Item, :tag, :Tag
  diff :Tag, "import"
}
```

But this rule will erroneously match on your item, because it will latch on to the `luxury` tag, since all facts are processed independently of each other, and `luxury` is indeed not equal to `import`. This is the "there is a tag that is not X" scenario.

In this situation, what you want to do instead is `neg :Item, :tag, "import"` to say "there is no tag X".

### less

```ruby
less x, y
```

`less` passes if `x < y`.

### greater

```ruby
greater x, y
```

`greater` passes if `x > y`.

### in_list, not_in_list

```ruby
in_list value, list

not_in_list value, list
```

`in_list` passes if the second argument includes the first one; `not_in_list` passes if it does not.

### assert

```ruby
assert { |token|
  # ...
}

assert :A, :B, :C, ... do |a, b, c, ...|
  # ...
end
```

`assert` passes if the block returns a truthy value.

## Aggregates

Aggregates calculate a value across all matching result sets and pass it forward. They all have the same base form:

```ruby
aggregate :NewVar, over: :Var, map: ->(token) { ... }, using: ->(values) { ... }, partition: [:Var1, :Var2, ...]
```

`NewVar` is the variable that will receive the result of the aggregation.

`over` is the variable that is fed to the aggregation function. Alternatively, a `map` function with more complex logic may be provided.

`using` is the actual aggregation function.

`partition` splits all tokens into groups based on the provided variables. If no partitions are given, all tokens are lumped in the same group.

The execution order is `tokens -> partition -> map/over -> using`.

For convenience, the following matchers are defined with pre-declared `using` arguments:

### `count`

### `min`

### `max`

### `sum`

### `product`