require 'rubygems'

unless ENV['NO_COVERALLS']
  require 'simplecov' if RUBY_VERSION.to_f > 1.8
  require 'coveralls'
  Coveralls.wear! do
    add_filter '/bundle/'
    add_filter '/spec/'
    add_filter '/tmp/'
  end
end

begin
  require 'spork'
rescue LoadError
  module Spork
    def self.prefork
      yield
    end

    def self.each_run
      yield
    end
  end
end

Spork.prefork do
  require 'rspec/autorun'
  require 'aruba/api'

  if RUBY_PLATFORM == 'java'
    # Works around https://jira.codehaus.org/browse/JRUBY-5678
    require 'fileutils'
    ENV['TMPDIR'] = File.expand_path('../../tmp', __FILE__)
    FileUtils.mkdir_p(ENV['TMPDIR'])
  end

  Dir['./spec/support/**/*.rb'].map {|f| require f}

  class NullObject
    private
    def method_missing(method, *args, &block)
      # ignore
    end
  end

  module SandboxHelpers
    def current_sandboxed_output_stream
      RSpec.configuration.output_stream ||= StringIO.new
    end
  end

  module Sandboxing
    def self.sandboxed(&block)
      @orig_config = RSpec.configuration
      @orig_world  = RSpec.world
      @orig_example = RSpec.current_example
      new_config = RSpec::Core::Configuration.new
      new_config.output = StringIO.new
      new_world  = RSpec::Core::World.new(new_config)
      RSpec.configuration = new_config
      RSpec.world = new_world
      object = Object.new
      object.extend(RSpec::Core::SharedExampleGroup)

      (class << RSpec::Core::ExampleGroup; self; end).class_eval do
        alias_method :orig_run, :run
        def run(reporter=nil)
          RSpec.current_example = nil
          orig_run(reporter || NullObject.new)
        end
      end

      RSpec::Core::SandboxedMockSpace.sandboxed do
        object.instance_eval(&block)
      end
    ensure
      (class << RSpec::Core::ExampleGroup; self; end).class_eval do
        remove_method :run
        alias_method :run, :orig_run
        remove_method :orig_run
      end

      RSpec.configuration = @orig_config
      RSpec.world = @orig_world
      RSpec.current_example = @orig_example
    end
  end

  def in_editor?
    ENV.has_key?('TM_MODE') || ENV.has_key?('EMACS') || ENV.has_key?('VIM')
  end

  module EnvHelpers
    def with_env_vars(vars)
      original = ENV.to_hash
      vars.each { |k, v| ENV[k] = v }

      begin
        yield
      ensure
        ENV.replace(original)
      end
    end

    def without_env_vars(*vars)
      original = ENV.to_hash
      vars.each { |k| ENV.delete(k) }

      begin
        yield
      ensure
        ENV.replace(original)
      end
    end
  end

  RSpec.configure do |c|
    # structural
    c.alias_it_behaves_like_to 'it_has_behavior'
    c.around {|example| Sandboxing.sandboxed { example.run }}
    c.include SandboxHelpers
    c.include(RSpecHelpers)
    c.include Aruba::Api, :example_group => {
      :file_path => /spec\/command_line/
    }

    # Use the doc formatter when running individual files.
    # This is too verbose when running all spec files but
    # is nice for a single file.
    if c.files_to_run.one? && c.formatters.none?
      c.formatter = 'doc'
    end

    c.expect_with :rspec do |expectations|
      expectations.syntax = :expect
    end

    # runtime options
    c.color = !in_editor?
    c.filter_run :focus
    c.include EnvHelpers
    c.run_all_when_everything_filtered = true
    c.filter_run_excluding :ruby => lambda {|version|
      case version.to_s
      when "!jruby"
        RUBY_ENGINE == "jruby"
      when /^> (.*)/
        !(RUBY_VERSION.to_s > $1)
      else
        !(RUBY_VERSION.to_s =~ /^#{version.to_s}/)
      end
    }
  end
end

Spork.each_run do
end
