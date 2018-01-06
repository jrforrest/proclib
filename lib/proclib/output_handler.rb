require 'thread'
require 'proclib/errors'

module Proclib
  # Emits events for the given io pipe with relevant tagging info
  class OutputHandler
    # Calls its given callback with each line in the input written
    # to the buffer
    class LineBuffer
      NEWLINE = "\n"
      MAX_SIZE = 1024 * 10
      SIZE_ERROR_MESSAGE = "A line of greater than #{MAX_SIZE} bytes was " \
        "encountered from a process."

      MaxSizeExceeded = Class.new(Error)

      def initialize(&blk)
        @buf = String.new
        @callback = blk
      end

      def write(str)
        buf << str

        while buf.include?(NEWLINE)
          idx = buf.index(NEWLINE)
          callback.call(buf[0..(idx - 1)] + NEWLINE)
          self.buf = (buf[(idx + 1)..-1] || String.new)
        end

        if buf.bytesize > MAX_SIZE
          raise MaxSizeExceeded, SIZE_ERROR_MESSAGE
        end
      end

      def flush
        callback.call(buf + "\n") unless buf.empty?
      end

      private

      attr_accessor :buf
      attr_reader :callback
    end

    READ_SIZE = 1024
    Message = Class.new(Struct.new(:process_tag, :pipe_name, :line))

    attr_reader :type, :command, :channel
    def initialize(type, command, channel:)
      @type, @command, @channel = type, command, channel
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

    def pipe
      @pipe ||= command.pipes[type]
    end

    def monitor
      while s = pipe.read(READ_SIZE)
        line_buffer.write(s)
      end

      line_buffer.flush
    end

    def line_buffer
      @line_buffer ||= LineBuffer.new do |line|
        channel.emit(:output, Message.new(command.tag, type, line))
      end
    end
  end
end
