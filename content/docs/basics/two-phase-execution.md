---
title: Two-phase execution
weight: 6
---

# Two-phase execution

This is a good place to mention an important detail that has caused some confusion among users.

People sometimes assume that the literal contents of `forall` and `make` are executed for each fact, and try to put arbitrary Ruby statements in there, but this is not what's happening. Rule declarations are interpreted **once** in the compilation phase which builds internal structures corresponding to the declaration, and those structures are then traversed when facts are added. Any statement that is not part of the rule DSL will not be recognized by the compiler and will not have the effect you intended. Any custom code must be wrapped in appropriate rule DSL clauses.

As a consequence of this, any Ruby variable used in a matcher declaration will effectively become constant in the rule execution phase, keeping the value that was visible during compilation. One common example is trying to use `Time.now` in a template, expecting it to evaluate at the moment of matching. The [`assign`](../../matchers/#assign) matcher should be used for this instead.
