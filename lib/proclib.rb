require 'open3'
require 'thread'

require 'proclib/version'

require 'proclib/event_emitter'
require 'proclib/process'
require 'proclib/executor'

module Proclib
  module Methods
    def run(cmdline, tag: nil, log_to_console: false, capture_output: true)
      process = Process.new(cmdline, tag: tag || cmdline[0..20])
      executor = Executor.new(process,
        log_to_console: log_to_console,
        cache_output: capture_output)
      executor.run_sync
    end
  end

  class << self
    include Methods
  end
end
