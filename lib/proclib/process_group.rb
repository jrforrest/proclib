require 'proclib/event_emitter'

module Proclib
  class ProcessGroup
    include EventEmitter::Producer

    def initialize(processes)
      @processes = processes
    end

    def spawn
      processes.each do |process|
        process.bind_to(channel)
        process.spawn
      end

      start_watch_thread
    end

    def kill
      processes.each(&:kill)
    end

    private
    attr_reader :processes

    def start_watch_thread
      Thread.new { channel.watch }
    end

    def channel
      @channel ||= EventEmitter::Channel.new.tap do |channel|
        channel.on(:output) {|ev| push(ev) }
        channel.on(:exit) do |ev|
          emit(:complete) if processes.all?(&:complete?)
        end
      end
    end
  end
  private_constant :ProcessGroup
end
