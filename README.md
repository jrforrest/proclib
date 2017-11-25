# Proclib

High-level tools for subprocess management in Ruby

## Status

I use Proclib as a suport library for a couple of systems utilities that I'm
slowly preparing for a proper open-source release.  Proclib is one of
several extracted libraries that I'll be maturing into their own projects.

Proclib is currently beta quality at best.

## Usage

See `examples/main.rb`

Currenty, Proclib doesn't do anything on exit to kill child processes, so you'll
need to trap the appropriate signals yourself to keep from leaving orphaned processes
around.

## License

[MIT License](http://opensource.org/licenses/MIT).
