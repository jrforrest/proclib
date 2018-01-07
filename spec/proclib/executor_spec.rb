require 'spec_helper'

require 'proclib/executor'

module Proclib
  describe Executor do
    subject(:executor) { described_class.new(commands, **opts) }

    let(:process_count) { 1 }

    let(:opts) { Hash.new }
    let(:commands) { double(:commands) }
    let(:channel) { double(:channel, close: nil) }
    let(:processes) { process_count.times.map { process_double } }

    before do
      allow(channel).to(receive(:each)).tap do |expectation|
        channel_messages.each {|m| expectation.and_yield(m) }
      end

      allow(executor).to receive(:processes).and_return(processes)
      allow(executor).to receive(:channel).and_return(channel)
    end

    describe 'running a process' do
      let(:channel_messages) { [ exit_message(0) ] }

      it 'reports success' do
        res = subject.run_sync
        expect(subject.run_sync).to be_success
      end

      it 'closes the channel' do
        expect(channel).to receive(:close)
        subject.run_sync
      end
    end

    describe '#run_sync' do
      describe 'return value' do
        subject { super().run_sync }

        let(:process_count) { exit_statuses.size }
        let(:channel_messages) { exit_statuses.map {|s| exit_message(s) } }

        context 'when all processes exit successfully' do
          let(:exit_statuses) { [0, 0, 0] }
          it { is_expected.to be_success }
        end

        context 'when one process does not exit successfully' do
          let(:exit_statuses) { [0, 255, 0] }
          it { is_expected.to be_failure }
        end
      end
    end

    describe 'capturing output' do
      let(:output_cache) { double(:output_cache) }
      let(:cache_output) { true }
      let(:opts) { { cache_output: cache_output } }
      let(:channel_messages) do
        [ output_message, output_message, exit_message(0) ]
      end

      before do
        allow(subject).to receive(:output_cache).and_return(output_cache)
      end

      it 'sends the output to the output cache' do
        expect(output_cache).to receive(:<<).exactly(2).times
        subject.run_sync
      end

      context 'with cache_output option disabled' do
        let(:cache_output) { false }

        it 'does not send the output to the output cache' do
          expect(output_cache).not_to receive(:<<)
          subject.run_sync
        end
      end
    end

    private

    def exit_message(status)
      channel_message(:exit, status)
    end

    def output_message
      channel_message(:output, double)
    end

    def channel_message(type, data)
      double(:channel_message, type: type, data: data)
    end

    def process_double
      double(:process, spawn: nil)
    end
  end
end
