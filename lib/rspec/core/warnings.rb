module RSpec

  # @private
  #
  # Used internally to print deprecation warnings
  def self.deprecate(deprecated, data = {})
    call_site = caller.find { |line| line !~ %r{/lib/rspec/(core|mocks|expectations|matchers|rails)/} }

    RSpec.configuration.reporter.deprecation(
      {
        :deprecated => deprecated,
        :call_site => CallerFilter.first_non_rspec_line
      }.merge(data)
    )
  end

  # @private
  #
  # Used internally to print deprecation warnings
  def self.warn_deprecation(message)
    RSpec.configuration.reporter.deprecation :message => message
  end

  # @private
  #
  # Used internally to print warnings
  def self.warning(text, options={})
    warn_with "WARNING: #{text}.", options
  end

  # @private
  #
  # Used internally to longer warnings
  def self.warn_with(message, options = {})
    call_site = caller.find { |line| line !~ %r{/lib/rspec/(core|mocks|expectations|matchers|rails)/} }
    message << " Called from #{call_site}."
    ::Kernel.warn message
  end

end
