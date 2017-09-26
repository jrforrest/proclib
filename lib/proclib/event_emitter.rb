module Proclib
  # Async event utils
  module EventEmitter
    Event = Struct.new(:name, :sender, :data)
    Error = Class.new(StandardError)

    # Provides callbacks on events from bound producers
    class Channel
      COMPLETE = Object.new

      def initialize
        @queue = ::Queue.new
        @handlers = Hash.new
      end

      def push(msg)
        unless msg.kind_of?(Event)
          raise(Error, "EventEmitter::Queue should only handle messages of type EventEmitter::Event")
        end

        @queue.push(msg)
      end

      def on(name, &handler)
        (handlers[name] ||= Array.new) << handler
      end

      def watch
        while ev = @queue.pop
          break if ev == COMPLETE
          handlers[ev.name].each {|h| h.call(ev)} if handlers[ev.name]
        end
      end

      def finalize
        @queue.push(COMPLETE)
      end

      private
      attr_reader :handlers
    end

    # Emits messages to bound channel
    module Producer
      def bind_to(queue)
        @event_queue = queue
      end

      def bound?
        ! @event_queue.nil?
      end

      private

      def bubble_events_for(child)
        if bound?
          child.bind_to(@event_queue)
        end
      end

      def emit(name, data = nil)
        push(Event.new(name, self, data))
      end

      def push(event)
        @event_queue.push(event) if bound?
      end
    end
  end
  private_constant :EventEmitter
end
