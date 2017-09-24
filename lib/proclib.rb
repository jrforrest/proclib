require 'open3'
require 'thread'

require 'proclib/version'

require 'proclib/event_emitter'
require 'proclib/process'
require 'proclib/executor'

module Proclib
  module Methods
    def run(cmdline, tag:, log_to_console: true)
      process = Process.new(cmdline, tag: tag)
      executor = Executor.new(process, log_to_console: log_to_console)
      executor.run_sync
    end
  end

  class << self
    include Methods
  end
end
