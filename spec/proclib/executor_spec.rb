require 'spec_helper'

require 'proclib/executor'

module Proclib
  describe Executor do
    class MockRunnable
      include EventEmitter::Producer

      def spawn
        Thread.new { emit(:exit, OpenStruct.new(status: 0)) }
      end
    end

    let(:runnable) { MockRunnable.new }

    subject { described_class.new(runnable) }

    describe '#run_sync' do
      it 'returns the result' do
        expect(subject.run_sync.status).to eql(0)
      end
    end
  end
end
