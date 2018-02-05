require 'proclib/commands/base'
require 'open3'

module Proclib
  module Commands
    class Local < Base
      def spawn
        spawn = -> do
          pipes.stdin, pipes.stdout, pipes.stderr, @wait_thread = Open3.popen3(env, cmdline)
        end

        if run_dir
          Dir.chdir(run_dir) { spawn.call }
        else
          spawn.call
        end

        unless stdin.nil?
          until stdin.eof?
            pipes.stdin.write(stdin.read(STDIN_BUF_SIZE))
          end

          stdin.close
        end

        pipes.stdin.close
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
