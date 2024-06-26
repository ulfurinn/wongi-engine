# Wongi::Engine

[![Gem](https://img.shields.io/gem/v/wongi-engine.svg)](https://rubygems.org/gems/wongi-engine/)
[![Build Status](https://github.com/ulfurinn/wongi-engine/actions/workflows/test.yml/badge.svg)](https://github.com/ulfurinn/wongi-engine/actions/workflows/test.yml)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/R6R0YVX79)

This is a pure-Ruby forward-chaining rule engine based on the classic [Rete algorithm](http://en.wikipedia.org/wiki/Rete_algorithm).

Ruby >= 2.7 and JRuby are supported. Rubinius should work but isn't actively supported.

## Documentation

There is no API documentation, as most of the library's interfaces are for internal use only and would not be safe to use directly.

Instead, follow the [tutorial](https://ulfurinn.github.io/wongi-engine/) and stick to the constructs described in it.

## Upgrading

Until there is a 1.0 release, all minor versions should be treated as potentially breaking.

Always test your rules extensively. There's always a chance of you finding a bug in the engine that is only triggered by a very specific rule configuration.

[Feature annoucements](https://github.com/ulfurinn/wongi-engine/issues?q=is%3Aissue+label%3Aannoucement)

[Open discussions](https://github.com/ulfurinn/wongi-engine/issues?q=is%3Aopen+is%3Aissue+label%3Adiscussion)

## Acknowledgements

The Rete implementation in this library largely follows the outline presented in [\[Doorenbos, 1995\]](http://reports-archive.adm.cs.cmu.edu/anon/1995/CMU-CS-95-113.pdf).
