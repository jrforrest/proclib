require 'open3'
require 'thread'

require 'proclib/version'

require 'proclib/event_emitter'
require 'proclib/process'
require 'proclib/process_group'
require 'proclib/executor'

module Proclib
  module Methods
    def run(cmd, tag: nil, log_to_console: false, capture_output: true)
      runnable = if cmd.kind_of? String
         Process.new(cmd, tag: tag || cmd[0..20])
      elsif cmd.kind_of?(Hash)
        processes = cmd.map {|(k,v)| Process.new(v, tag: k || v[0..20]) }
        ProcessGroup.new(processes)
      else
        raise ArgumentError, "Unexpected type for `cmd`: #{cmd.class}.  \n"\
          "Expected String or Hash"
      end

      executor = Executor.new(runnable,
        log_to_console: log_to_console,
        cache_output: capture_output)
      executor.run_sync
    end
  end

  class << self
    include Methods
  end
end
