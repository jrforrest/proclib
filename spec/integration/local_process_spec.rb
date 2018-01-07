require 'pathname'

require 'spec_helper'

require 'proclib/process'
require 'proclib/command'
require 'proclib/channel'

module Proclib
  describe 'Running a local process' do
    let(:channel) { Channel.new(:output, :exit) }
    let(:process) { Process.new(command, channel: channel) }
    let(:command) { Commands::LocalCommand.new(**opts) }
    let(:run_dir) { nil }

    let(:tag) { :test_command }

    describe 'listing the test directory' do
      let(:test_dir) { Pathname.new(__dir__).join('..', 'fixtures', 'test_dir') }
      let(:opts) { { cmdline: "ls #{test_dir}" } }
      let(:test_dir_files) { %w{one two three four} }

      let(:channel_messages) do
        Array.new.tap do |messages|
          channel.each do |message|
            messages.push(message)
            channel.close if message.type == :exit
          end
        end
      end

      before { process.spawn }

      it 'emits some output lines for each file' do
        test_dir_files.each do |filename|
          expect(output_message_with_file(filename)).not_to be_nil
        end
      end

      it 'emits exit after output' do
        expect(channel_messages.last.type).to eql(:exit)
      end

      private

      def output_message_with_file(name)
        channel_messages.find {|m| m.data.line == name + "\n" }
      end
    end
  end
end
