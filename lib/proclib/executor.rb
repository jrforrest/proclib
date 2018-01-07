require 'proclib/loggers/console'
require 'proclib/output_cache'
require 'proclib/channel'
require 'proclib/process'
require 'proclib/result'

module Proclib
  # Runs a list of commands simultaenously, providing callbacks on their output
  # lines and exits, as well as optional output logging and caching.
  class Executor
    attr_reader :log_to_console, :cache_output, :commands, :callbacks
    alias_method :log_to_console?, :log_to_console
    alias_method :cache_output?, :cache_output

    def initialize(commands, log_to_console: false, cache_output: false)
      @commands, @log_to_console, @cache_output =
        commands, log_to_console, cache_output
      @callbacks = Struct.new(:exit, :output).new([], [])
    end

    def run_sync
      start
      wait
    end

    def start
      processes.each(&:spawn)
    end

    def wait
      channel.each do |message|
        handle_exit(message) if message.type == :exit
        handle_output(message) if message.type == :output
      end

      result
    end

    def on_exit(&blk)
      callbacks.exit << blk
    end

    def on_output(&blk)
      callbacks.output << blk
    end

    def exit_states
      @exit_states ||= Array.new
    end

    private

    def result
      Result.new(
        exit_code: aggregate_exit_code,
        output_cache: (output_cache if cache_output?)
      )
    end

    def aggregate_exit_code
      if exit_states.all? {|c| c == 0}
        0
      elsif exit_states.size == 1
        exit_states.first
      else
        1
      end
    end

    def handle_exit(message)
      exit_states << message.data
      channel.close if exit_states.size == processes.size
      callbacks.exit.each {|c| c[message.data] }
    end

    def handle_output(message)
      callbacks.output.each {|c| c[message.data]}

      console_logger << message.data  if log_to_console?
      output_cache << message.data if cache_output?
    end

    def output_cache
      @output_cache ||= OutputCache.new
    end

    def console_logger
      @console_logger ||= Loggers::Console.new
    end

    def channel
      @channel ||= Channel.new(:output, :exit)
    end

    def processes
      commands.map {|c| Process.new(c, channel: channel) }
    end
  end
end
