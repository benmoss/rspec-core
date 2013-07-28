module RSpec
  module Core
    module Warning
      # @private
      #
      # Used internally to print warnings
      def warning(text, options={})
        warn_with "WARNING: #{text}.", options
      end

      def warn_with(message, options = {})
        line = caller.find { |line| line !~ %r{/lib/rspec/(core|mocks|expectations|matchers|rails)/} }
        message << " Use #{options[:replacement]} instead." if options[:replacement]
        message << " Called from #{line}."
        ::Kernel.warn message
      end
    end
  end

  extend(Core::Warning)
end
