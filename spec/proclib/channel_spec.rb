require 'proclib/channel'
require 'spec_helper'

describe Proclib::Channel do
  subject { described_class.new(*allowed_messages) }

  describe 'putting a message' do
    let(:allowed_messages) { %i(hello) }

    context 'when the message is allowed' do
      let(:retrieved_message) { subject.first }

      it 'emits the message' do
        subject.emit(:hello, 'world')
        expect(retrieved_message.type).to eql(:hello)
        expect(retrieved_message.data).to eql('world')
      end
    end

    context 'when the message is not allowed' do
      it 'raises an UnexpectedMessageType error' do
        expect { subject.emit(:blerp) }.
          to raise_error(Proclib::Channel::UnexpectedMessageType)
      end
    end
  end
end
