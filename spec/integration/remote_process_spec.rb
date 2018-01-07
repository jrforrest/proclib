require 'pathname'

require 'spec_helper'

require 'proclib/process'
require 'proclib/command'
require 'proclib/channel'

require 'docker'

module Proclib
  describe 'running a command on a remote server', :docker do
    before(:all) do
      image = Docker::Image.build_from_dir(File.join(__dir__, '..'))
      @container = Docker::Container.create(
        image: image.id,
        "ExposedPorts": { "2202/tcp" => {} },
        "HostConfig" => {
          "PortBindings" => {
            '2202/tcp' => [{"HostPort" => "2202"}]
          }
        }
      )

      @container.start()
    end

    after(:all) do
      @container.stop
    end

    describe 'Running a remote process' do
      let(:channel) { Channel.new(:output, :exit) }
      let(:process) { Process.new(command, channel: channel) }
      let(:command) { Commands::SshCommand.new(**opts) }

      let(:ssh_opts) do
        { user: 'root',
          password: 'blerp',
          host: 'localhost',
          port: 2202,
          paranoid: false }
      end

      let(:opts) { { ssh: ssh_opts,  cmdline: 'echo herro!'} }

      before { process.spawn }

      let(:channel_messages) do
        Array.new.tap do |messages|
          channel.each do |message|
            messages.push(message)
            channel.close if message.type == :exit
          end
        end
      end

      it 'can run a command on the remote host' do
        expect(channel_messages[0].data.line).to eql("herro!\n")
        expect(channel_messages[1].data).to eql(0)
      end
    end
  end
end
