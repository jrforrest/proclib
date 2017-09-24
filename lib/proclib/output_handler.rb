require 'thread'

module Proclib
  # Emits events for the given io pipe with relevant tagging info
  class OutputHandler
    Message = Class.new(Struct.new(:process_tag, :pipe_name, :line))

    include EventEmitter::Producer

    def initialize(process_tag, pipe_name, pipe)
      @process_tag, @pipe_name, @pipe = process_tag, pipe_name, pipe
    end

    def start
      @thread = Thread.new { monitor }
    end

    def wait
      @thread.join
    end

    def kill
      @thread.exit
    end

    private

    attr_reader :process_tag, :pipe_name, :pipe

    def monitor
      pipe.each_line do |line|
        emit(:output, Message.new(process_tag, pipe_name, line))
      end
      emit(:end_of_output)
    end
  end
end
