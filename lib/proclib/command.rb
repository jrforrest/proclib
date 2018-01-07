require 'open3'
require 'ostruct'

require 'proclib/errors'

require 'net/ssh'

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

    class SshCommand < Command
      attr_reader :ssh_opts

      SSHError = Class.new(Error)

      def initialize(ssh:, **args)
        @ssh_opts = ssh.clone
        super(**args)
      end

      def spawn
        write_pipes

        open_channel do |ch|
          ch.exec(cmdline) do |_, success|
            raise SSHError, "Command Failed" unless success
          end
        end
      end

      def wait
        ssh_session.loop
      end

      private

      def open_channel
         ssh_session.open_channel do |channel|
          channel.on_open_failed do |ch, code, desc, lang|
            raise SSHError, desc
          end

          channel.on_data {|_, data| write_pipes[:stdout].write(data) }

          channel.on_extended_data {|_, data| write_pipes[:stderr].write(data) }

          channel.on_request("exit-status") do |_, data|
            write_pipes.each {|k,v| v.close }
            @result = data.read_long
          end

          yield channel
        end
      end

      def write_pipes
        @write_pipes ||= %i(stdout stderr).map do |type|
          read, write = IO.pipe
          pipes[type] = read
          [type, write]
        end.to_h
      end

      def ssh_session
        @ssh_session ||= Net::SSH.start(*ssh_params, ssh_opts).tap do |session|
          session.chdir(run_dir) unless run_dir.nil?
        end
      end

      def ssh_params
        %i(host user).map {|i| ssh_opts.delete(i)}.compact
      end
    end
  end
end
