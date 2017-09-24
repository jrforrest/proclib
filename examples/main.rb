require 'pry'
require 'pathname'

Thread.abort_on_exception = true

$LOAD_PATH.unshift Pathname.new(File.expand_path(__FILE__)).join('..', '..', 'lib').to_s

require_relative '../lib/proclib'

# Run a quick command

Proclib.run("echo herorooo >&2", tag: :test, log_to_console: true)
