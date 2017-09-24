require 'open3'
require 'ostruct'

require 'proclib/output_handler'

module Proclib
  # Runs a single process, emitting output, state changes and exit status
  class Process
    include EventEmitter::Producer

    attr_reader :cmdline, :tag

    Error = Class.new(StandardError)

    def initialize(cmdline, tag:)
      @cmdline = cmdline
      @tag = tag
      @state = :ready
      @io_handlers = OpenStruct.new
      @pipes = OpenStruct.new
    end

    def spawn
      raise(Error, "Already started process") unless @wait_thread.nil?

      pipes.stdin, pipes.stdout, pipes.stderr, @wait_thread = Open3.popen3(cmdline)
      start_output_emitters
      start_watch_thread
    end

    private
    attr_reader :wait_thread, :io_handlers, :pipes

    def start_watch_thread
      Thread.new do
        result = wait_thread.value
        io_handlers.each_pair {|(_, e)| e.wait }
        @state = :done
        emit(:exit, result)
      end
    end

    def start_output_emitters
      %i(stderr stdout).map do |type|
        io_handlers[type] = OutputHandler.new(tag, type, pipes[type]).tap do |handler|
          bubble_events_for(handler)
          handler.start
        end
      end
    end

    def check_started
      if wait_thread.nil?
        raise Error, "Process `#{tag}` is not yet started!"
      end
    end

    def output_buffer
      check_started
      @output_buffer ||= OutputBuffer.new(tag, stdout_pipe, stderr_pipe).tap do |buffer|
        bubble_events_for(buffer)
      end
    end
  end
  private_constant :Process
end
