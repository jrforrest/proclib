require 'proclib/process'

module Proclib
  class SSHProcess < Process
    def spawn
      cmdline = "cd #{run_dir} && #{self.cmdline}" unless run_dir.nil?

      write_pipes = Hash.new

      %i(stdout stderr).each do |type|
        pipes[type], write_pipes[type] = IO.pipe
      end

      ssh_session.exec cmdline do |ch, stream, data|
        write_pipes[stream].write(data)
      end

      start_output_emitters
    end

    private

    def wait_thread
      Thread.new do
        result = wait_thread.value
        io_handlers.each_pair {|(_, e)| e.wait }
        @state = :complete
        emit(:exit, @result)
        emit(:complete)
      end
    end
  end
end
