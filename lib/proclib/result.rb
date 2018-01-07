require 'proclib/errors'

module Proclib
  class Result
    OutputNotAvailable = Class.new(Error)

    attr_reader :exit_code
    def initialize(exit_code:, output_cache: nil)
      @exit_code, @output_cache = exit_code, output_cache
    end

    %i(stdin stdout).each do |type|
      define_method(type) do
        if @output_cache.nil?
          raise OutputNotAvailable, "`#{type}` not cached for this process. "\
            "ensure output caching is enabled when invoking."
        end

        @output_cache.pipe_aggregate(type)
      end
    end

    def success?
      exit_code == 0
    end

    def failure?
      !success?
    end
  end
end
