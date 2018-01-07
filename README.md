# Proclib

High-level tools for subprocess management in Ruby

## Status

I use Proclib as a suport library for a couple of systems utilities that I'm
slowly preparing for a proper open-source release.  Proclib is one of
several extracted libraries that I'll be maturing into their own projects.

**Disclaimer**

Proclib is currently beta quality at best. The code is written in a
fairly unmaintainable fashion at the moment, and I definitely don't
suggest anyone not interested in putting some work into the library
use this in its current state.

## Usage

See acceptance specs in `spec/acceptance`.

Currenty, Proclib doesn't do anything on exit to kill child processes, so you'll
need to trap the appropriate signals yourself to keep from leaving orphaned processes
around.

## Issues

- Even when caching output, Proclib expects short lines meant for user consumption
  in output from its processes, and will crash on more than a few KB per line.

## License

[MIT License](http://opensource.org/licenses/MIT).
