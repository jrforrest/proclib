require 'proclib/commands/base'
require 'net/ssh'

module Proclib
  module Commands
    class Ssh < Base
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
