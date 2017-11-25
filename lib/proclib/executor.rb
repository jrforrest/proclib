require 'proclib/event_emitter'
require 'proclib/loggers/console'
require 'proclib/output_cache'

module Proclib
  # Runs a runnable, handling emitted events and dispatching to configured
  # facilities
  class Executor
    attr_reader :opts

    def initialize(runnable, opts = {})
      @runnable = runnable
      @opts = opts
    end

    def on(name, &block)
      channel.on(name, &block)
    end

    def run_sync
      configure
      runnable.spawn
      channel.watch
      return @status, *%i{stdout stderr}.map {|i| output_cache.pipe_aggregate(i) }
    end

    private

    attr_reader :runnable, :log_to_console

    def configure
      runnable.bind_to(channel)
      channel.on(:complete) do |event|
        @status = event.data.to_i
        channel.finalize
      end
      configure_output
    end

    def configure_output
      channel.on(:output) {|e| console_logger << e.data } if opts[:log_to_console]
      channel.on(:output) {|e| output_cache << e.data} if opts[:cache_output]

      if opts[:on_output]
        channel.on(:output) do |e|
          msg = e.data
          opts[:on_output].call(msg.line, msg.process_tag, msg.pipe_name)
        end
      end
    end

    def output_cache
      @output_cache ||= OutputCache.new
    end

    def console_logger
      @console_logger ||= Loggers::Console.new
    end

    def channel
      @channel ||= EventEmitter::Channel.new
    end
  end
end
