require 'thread'

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

      include EventEmitter::Producer

      def initialize(&blk)
        @buf = String.new
        @callback = blk
      end

      def write(str)
        buf << str

        if str.include?(NEWLINE)
          idx = buf.index(NEWLINE)
          callback.call(buf[0..(idx - 1)] + NEWLINE)
          self.buf = (buf[(idx + 1)..-1] || String.new)
        elsif buf.bytesize > MAX_SIZE
          raise MaxSizeExceeded, SIZE_ERROR_MESSAGE
        end
      end

      private

      attr_accessor :buf
      attr_reader :callback
    end

    READ_SIZE = 1024
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
      while s = pipe.read(READ_SIZE)
        line_buffer.write(s)
      end
      emit(:end_of_output)
    end

    def line_buffer
      @line_buffer ||= LineBuffer.new do |line|
        emit(:output, Message.new(process_tag, pipe_name, line))
      end
    end
  end
end
