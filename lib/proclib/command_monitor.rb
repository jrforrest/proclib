require 'proclib/output_handler'

module Proclib
  # Watches the given command, emitting the appropriate events
  # on the given channel when the command does something
  class CommandMonitor
    attr_reader :command, :channel

    def initialize(command, channel:)
      @command, @channel = command, channel
    end

    def start
      io_handlers.each(&:start)
    end

    def wait
      io_handlers.each(&:wait)
    end

    private

    def io_handlers
      @io_handlers ||= %i(stderr stdout).map do |type|
         OutputHandler.new(type, command, channel: channel)
      end
    end
  end
end
