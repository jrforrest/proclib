require 'thread'

module Proclib
  # Simple thread-safe communication mechanism
  class Channel
    include Enumerable

    Message = Struct.new(:type, :data)
    UnexpectedMessageType = Class.new(StandardError)

    attr_reader :allowed_types

    def initialize(*types)
      @allowed_types = types
    end

    def emit(type, data = nil)
      unless allowed_types.include?(type)
        raise UnexpectedMessageType,
          "Message type expected to be one of `#{allowed_types}`.  "\
            "Got: `#{type}`"
      end

      queue.push(Message.new(type, data))
    end

    def close
      queue.push(:done)
    end

    def each
      raise(ArgumentError, 'Block Expected!') unless block_given?

      while msg = queue.pop
        break if msg == :done
        yield msg
      end
    end

    def queue
      @queue ||= Queue.new
    end
  end
end
