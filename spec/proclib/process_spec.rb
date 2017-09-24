require 'spec_helper'

module Proclib
  describe Process do
    let(:command) { 'exit 0' }
    let(:channel) { EventEmitter::Channel.new }

    subject do
      described_class.new(command, tag: 'test').tap do |p|
        p.bind_to(channel)
      end
    end

    describe '#spawn' do
      let(:received_exits) { Array.new }

      it 'spawns a process that will exit' do
        channel.on(:exit) {|e| received_exits << e; channel.finalize }
        subject.spawn
        expect { channel.watch }.to change { received_exits.count }.by(1)
      end
    end
  end
end
