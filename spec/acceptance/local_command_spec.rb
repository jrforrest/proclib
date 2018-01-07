require 'proclib'

require 'spec_helper'

describe Proclib do
  describe '#run' do
    let(:opts) { {} }

    subject { Proclib.run(cmd, **opts) }

    context 'with a good command' do
      let(:cmd) { 'echo hi' }

      it 'runs the command successfully' do
        expect(subject).to be_success
      end
    end

    context 'with a bad command' do
      let(:cmd) { 'false' }

      it 'runs the command and reports failure' do
        expect(subject).to be_failure
      end
    end

    context 'when capturing output' do
      let(:cmd) { 'echo "Hello\nWorld"'}
      let(:opts) { { capture_output: true } }

      it 'makes the command output available in the result' do
        expect(subject.stdout).to eql(["Hello\n", "World\n"])
      end
    end

    context 'when setting a run dir' do
      let(:cmd) { "ls" }
      let(:opts) do
        { cwd: File.join(__dir__, '..', 'fixtures', 'test_dir'),
          capture_output: true }
      end

      it 'runs the command in the given directory' do
        expect(subject.stdout).to eql(["four\n", "one\n", "three\n", "two\n"])
      end
    end
  end
end
