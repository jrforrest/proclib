require 'spec_helper'
require 'proclib/output_handler'

describe Proclib::OutputHandler do
  describe 'emitting messages from the command' do
    let(:subject) { described_class.new(:stdout, command, channel: channel) }
    let(:channel) { double(:channel, emit: nil) }
    let(:command) { double(:command, tag: 'imacommand', pipes: pipes) }
    let(:pipes) { { stdout: stdout_read } }
    let(:stdout_write) { stdout_pipe[1] }
    let(:stdout_read) { stdout_pipe[0] }
    let(:stdout_pipe) { IO.pipe }

    let(:emitted_messages) { Array.new }
    let(:last_message) { emitted_messages.last }

    before do
      allow(channel).to receive(:emit) do |type, message|
        emitted_messages.push(message)
      end

      stdout_write.write(input)
      stdout_write.close
      subject.start
      subject.wait
    end

    context 'with a single line' do
      let(:input) { "Hello\n" }

      it 'reports a line received from the stdout pipe' do
        expect(last_message.process_tag).to eql('imacommand')
        expect(last_message.pipe_name).to eql(:stdout)
        expect(last_message.line).to eql(input)
      end
    end

    context 'when there\'s no newline in the command\'s output' do
      let(:input) { 'hi' }

      it 'emites a line containing anything not emitted' do
        expect(last_message).to_not be_nil
        expect(last_message.line).to eql("hi\n")
      end
    end

    context 'when there\'s multiple lines' do
      let(:lines) { ["Boy howdy", "how are you", "today world?"] }
      let(:input) { lines.join("\n") }

      it 'emits multiple messages in order' do
        emitted_messages.zip(lines).each do |(message, line)|
          expect(message.line).to eql(line + "\n")
        end
      end
    end
  end

  describe Proclib::OutputHandler::LineBuffer do
    subject { described_class.new {|l| emitted_lines.push(l) } }
    let(:emitted_lines) { Array.new }

    context 'with multiple lines at once' do
      let(:lines) { %w{one two three} }

      before do
        subject.write(lines.join("\n"))
        subject.flush
      end

      it 'emits a new line for each one in the input' do
        expect(emitted_lines).to eql(lines.map{|l| l + "\n"})
      end
    end

    context 'with a line longer than the max allowed' do
      let(:line) { 'xx' * described_class::MAX_SIZE }

      it 'raises an appropriate error' do
        expect { subject.write(line) }.
          to raise_error(described_class::MaxSizeExceeded)
      end
    end
  end
end
