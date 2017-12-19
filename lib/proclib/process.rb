require 'open3'
require 'ostruct'

require 'proclib/output_handler'

module Proclib
  # Runs a single process, emitting output, state changes and exit status
  class Process
    include EventEmitter::Producer

    attr_reader :cmdline, :tag, :env, :run_dir

    Error = Class.new(StandardError)

    def initialize(cmdline, tag:, env: {}, run_dir: nil)
      @cmdline = cmdline
      @tag = tag
      @env = env.map {|k,v| [k.to_s, v.to_s]}.to_h
      @state = :ready
      @io_handlers = OpenStruct.new
      @pipes = OpenStruct.new
      @run_dir = run_dir
    end

    def spawn
      raise(Error, "Already started process") unless @wait_thread.nil?

      spawn = -> do
        pipes.stdin, pipes.stdout, pipes.stderr, @wait_thread = Open3.popen3(env, cmdline)
      end

      if run_dir
        Dir.chdir(run_dir) { spawn.call }
      else
        spawn.call
      end

      @state = :running?
      start_output_emitters
      start_watch_thread
    end

    def complete?
      @state == :complete
    end

    private
    attr_reader :wait_thread, :io_handlers, :pipes

    def start_watch_thread
      Thread.new do
        result = wait_thread.value
        io_handlers.each_pair {|(_, e)| e.wait }
        @state = :complete
        emit(:exit, result)
        emit(:complete)
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
  end
  private_constant :Process
end
