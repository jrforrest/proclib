require 'proclib/process_group'

module Proclib
  describe ProcessGroup do
    let(:processes) { 2.times.map { process_double } }
    subject { described_class.new(processes) }

    describe '#spawn' do
      it 'spawns all of the processes' do
        processes.each {|p| expect(p).to receive(:spawn) }
        subject.spawn
      end

      after(:each) { Thread.list[1..-1].each(&:kill) }
    end

    private

    def process_double
      double(:process,
        bind_to: nil,
        spawn: nil)
    end
  end
end
