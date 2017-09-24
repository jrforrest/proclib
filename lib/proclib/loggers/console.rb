module Proclib
  module Loggers
    # Logs messages to the console
    class Console
      def log(message)
        STDOUT.printf("%s | %s | %s",
          message.process_tag, message.pipe_name, message.line)
      end
    end
  end
end
