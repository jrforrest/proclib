module Proclib
  module StringFormatting
    refine String do
      UnknownColor = Class.new(StandardError)

      COLORS = {
        yellow: 33,
        blue: 34,
        cyan: 36,
        default: 0,
      }

      def colorize(color)
        color = COLORS[color]

        if color.nil?
          raise(UnknownColor, "Unknown color for string: `#{color}`")
        end

        "\033[#{color}m#{self}\033[#{COLORS[:default]}m"
      end

      def truncate_to(size)
        self[0..size]
      end
    end
  end
end
