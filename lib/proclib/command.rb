require 'open3'
require 'ostruct'

require 'proclib/errors'

module Proclib
  module Commands
    class Command
      NotYetRunning = Class.new(Error)
      NotYetTerminated = Class.new(Error)

      attr_reader :tag, :cmdline, :env, :run_dir

      def initialize(tag: nil, cmdline:, env: {} , run_dir: nil)
        @env = env.map {|k,v| [k.to_s, v.to_s]}.to_h
        @cmdline = cmdline
        @tag = tag || cmdline[0..20]
        @run_dir = run_dir
      end

      def pipes
        @pipes ||= OpenStruct.new
      end

      def spawn
        raise NotImplementedError
      end

      def wait
        raise NotImplementedError
      end

      def result
        @result || raise(NotYetTerminated)
      end
    end
    private_constant :Command

    class LocalCommand < Command
      def spawn
        spawn = -> do
          pipes.stdin, pipes.stdout, pipes.stderr, @wait_thread = Open3.popen3(env, cmdline)
        end

        if run_dir
          Dir.chdir(run_dir) { spawn.call }
        else
          spawn.call
        end
      end

      def wait
        @result ||= wait_thread.value.to_i
      end

      private

      def wait_thread
        @wait_thread || raise(NotYetRunning)
      end
    end
  end
end
