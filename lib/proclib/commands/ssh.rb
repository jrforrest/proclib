require 'net/ssh'
require 'proclib/ssh_session'
require 'proclib/commands/base'

module Proclib
  module Commands
    class Ssh < Base
      SSHError = Class.new(Error)

      def initialize(ssh_session:, **args)
        @ssh_session = ssh_session
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

      def cmdline
        if !run_dir.nil?
          "cd #{run_dir}; #{super}"
        else
          super
        end
      end

      private

      attr_reader :ssh_session

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
    end
  end
end
