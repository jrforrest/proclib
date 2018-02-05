require 'pathname'

require 'spec_helper'

require 'proclib'

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

    let(:ssh_opts) do
      { user: 'root',
        password: 'blerp',
        host: 'localhost',
        port: 2202,
        paranoid: false }
    end

    describe Commands::Ssh do
      let(:channel) { Channel.new(:output, :exit) }
      let(:process) { Process.new(command, channel: channel) }
      let(:command) { Commands::Ssh.new(**opts) }


      let(:opts) { { ssh: ssh_opts, cmdline: 'echo herro!'} }

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

    describe 'Proclib.ssh_session' do
      let(:session) { Proclib.ssh_session(**ssh_opts) }

      it 'can run a command on the remote server' do
        expect(session.run('echo hi')).to be_success
      end

      it 'can run a command in a given directory' do
        expect(session.run('pwd', cwd: '/tmp').stdout.first).to eql("/tmp\n")
      end

      it 'can run multiple commands on the remote server' do
        expect(session.run('echo hi')).to be_success
        expect(session.run('echo bye')).to be_success
      end

      it 'can handle stdin' do
        expect(session.run('cat', stdin: StringIO.new('hello')).stdout.first).to eql("hello\n")
      end
    end
  end
end
