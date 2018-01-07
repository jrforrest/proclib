require 'thread'

require 'proclib/command_monitor'

module Proclib
  # Runs a command, emitting output, state changes and
  # exit status to the given channel
  class Process
    attr_reader :command, :channel

    Error = Class.new(StandardError)

    def initialize(command, channel:)
      @command, @channel, @state = command, channel, :ready
    end

    def spawn
      raise(Error, "Already started process") if @state != :ready

      @state = :started
      command.spawn

      output_emitter.start
      start_watch_thread
    end

    private
    attr_reader :wait_thread, :io_handlers

    def start_watch_thread
      @watch_thread ||= Thread.new do
        command.wait
        output_emitter.wait
        channel.emit(:exit, command.result)
      end
    end

    def output_emitter
      @output_emitter ||= CommandMonitor.new(command, channel: channel)
    end
  end
  private_constant :Process
end
