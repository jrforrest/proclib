require 'proclib/process'
require 'net/ssh'
require 'uri'

module Proclib
  class SSHProcess < Process
    SSHError = Class.new(Error)

    attr_reader :host

    def initialize(cmd, **args)
      @host = args.delete(:host) || raise(ArgumentError, 'host required')
      super(cmd, **args)
    end

    def spawn
      write_pipes = Hash.new

      %i(stdout stderr).each do |type|
        pipes[type], write_pipes[type] = IO.pipe
      end

      ssh_session.chdir(run_dir) unless run_dir.nil?
      ssh_session.open_channel do |channel|
        channel.exec(cmdline) do |ch, success|
          raise SSHError unless success

          channel.on_data {|_, data| write_pipes[:stdout].write(data) }
          channel.on_extended_data {|_, data| write_pipes[:stderr].write(data) }
          channel.on_request("exit-status") do |_, data|
            write_pipes.each {|k,v| v.close }
            io_handlers.each_pair {|(_, e)| e.wait }
            @state = :complete
            emit(:exit, data.read_long)
            emit(:complete)
          end
        end
      end

      ssh_session.exec cmdline do |ch, stream_type, data|
        write_pipes[stream_type].write(data)
      end

      start_output_emitters
      start_wait_thread
    end

    private

    def ssh_session
      @ssh_session ||= Net::SSH.start(uri.host, uri.user)
    end

    def uri
      @uri ||= URI.parse("ssh://" + host)
    end

    def start_wait_thread
      Thread.new { ssh_session.loop }
    end
  end
end
