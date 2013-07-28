require "spec_helper"

describe RSpec::Core::Warning do
  shared_examples_for "warning helper" do |helper|
    it 'warns with the message text' do
      expect(::Kernel).to receive(:warn).with /Message/
      RSpec.send(helper, 'Message')
    end

    it 'supplies replacement if set' do
      expect(::Kernel).to receive(:warn).with /Use replacement instead\./
      RSpec.send(helper, 'Message', :replacement => 'replacement')
    end

    it 'sets the calling line' do
      expect(::Kernel).to receive(:warn).with /#{__FILE__}:#{__LINE__+1}/
      RSpec.send(helper, 'Message')
    end
  end

  describe "#warning" do
    it 'prepends WARNING:' do
      expect(::Kernel).to receive(:warn).with /WARNING: Message\./
      RSpec.warning 'Message'
    end
    it_should_behave_like 'warning helper', :warning
  end

  describe "#warn_with message, options" do
    it_should_behave_like 'warning helper', :warn_with
  end
end
