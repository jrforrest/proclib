require 'proclib/string_formatting'

using Proclib::StringFormatting

module Proclib
  module Loggers
    class Console
      def log(message)
        STDOUT.printf("[ %-20s | %-8s ] %s",
          message.process_tag.to_s.truncate_to(20).colorize(:cyan),
          stylized_pipe_name(message),
          message.line)
      end
      alias_method :<<, :log

      private

      def stylized_pipe_name(message)
        color = ( {stdout: :blue, stderr: :yellow}[message.pipe_name] || :default )
        message.pipe_name.to_s.truncate_to(8).colorize(color)
      end
    end
  end
end
