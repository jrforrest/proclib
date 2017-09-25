module Proclib
  class OutputCache
    class Entry < Struct.new(:process_tag, :pipe_name, :cache)
      def <<(line)
        entry << line
      end

      private

      def entry
        (process_cache[pipe_name] ||= Array.new)
      end

      def process_cache
        (cache[process_tag] ||= Hash.new)
      end
    end

    def << message
      Entry.new(message.process_tag, message.pipe_name, cache) << message.line
    end

    def pipe_aggregate(name)
      process_caches.map {|c| c[name] || []}.flatten
    end

    private

    def process_caches
      cache.values
    end

    # Data structure: { process_tag: { stdin: [], stdout: [] } }
    def cache
      @cache ||= Hash.new
    end
  end

  private_constant :OutputCache
end
