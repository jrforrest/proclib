require 'proclib/event_emitter'
require 'proclib/loggers/console'

module Proclib
  # Runs a runnable, handling emitted events and dispatching to configured
  # facilities
  class Executor
    def initialize(runnable, log_to_console: false)
      @runnable = runnable
      @log_to_console = log_to_console
    end

    def on(name, &block)
      channel.on(name, &block)
    end

    def run_sync
      configure
      runnable.spawn
      channel.watch
      @result
    end

    private

    attr_reader :runnable, :log_to_console

    def configure
      runnable.bind_to(channel)
      channel.on(:exit) do |event|
        @result = event.data
        channel.finalize
      end
      configure_output
    end

    def configure_output
      channel.on(:output) {|e| console_logger.log(e.data) } if log_to_console
    end

    def console_logger
      @console_logger ||= Loggers::Console.new
    end

    def channel
      @channel ||= EventEmitter::Channel.new
    end
  end
end
