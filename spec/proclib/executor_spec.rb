require 'spec_helper'

require 'proclib/executor'

module Proclib
  describe Executor do
    class MockRunnable
      include EventEmitter::Producer

      def spawn
        Thread.new { emit(:exit, 0) }
      end
    end

    let(:runnable) { MockRunnable.new }

    subject { described_class.new(runnable) }

    describe '#run_sync' do
      it 'returns the result' do
        status, stdout, stderr = subject.run_sync
        expect(status).to eql(0)
      end

      context 'with caching' do
        subject { described_class.new(runnable, cache_output: true) }

        class MockRunnable
          def spawn
            Thread.new do
              emit(:output, OpenStruct.new(
                process_tag: :test,
                pipe_name: :stdout,
                line: 'oh hell yeah'))
              emit(:exit, 0)
            end
          end
        end

        it 'retains the output' do
          status, stdout, stderr = subject.run_sync
          expect(stdout).to eql(['oh hell yeah'])
        end

        it 'doesn\'t leave threads around' do
          subject.run_sync
          expect(Thread.list.count).to eql(1)
        end
      end
    end
  end
end
