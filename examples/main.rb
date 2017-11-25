require 'pry'
require 'pathname'

Thread.abort_on_exception = true

$LOAD_PATH.unshift Pathname.new(File.expand_path(__FILE__)).join('..', '..', 'lib').to_s

require_relative '../lib/proclib'

# Run a quick command with output logged to the console

Proclib.run("echo herorooo >&2", tag: :test, log_to_console: true)

# Pass env vars to subprocess

Proclib.run("echo $FOO", env: {FOO: 'hi'}, log_to_console: true)

_, stdout, _ = Proclib.run("ls /tmp/", capture_output: true)

puts "Files in /tmp"
puts stdout.join

cmd = "seq 1 5 | while read n; do echo $n; sleep 0.5; done"

Proclib.run({one: cmd, two: cmd}, log_to_console: true)

output_callback = -> (line, tag, pipe_name) {
  STDOUT.printf("%s:%s:%s", tag, pipe_name, line)
}

Proclib.run(cmd, tag: :count_things, on_output: output_callback)
