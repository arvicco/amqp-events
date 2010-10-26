require 'spec_helper'

describe AMQP::Events::Event, ' class' do
  subject { AMQP::Events::Event }

  specify { should respond_to :create }

  it 'should hide its new method' do
    expect { subject.new 'Test' }.to raise_error NoMethodError
  end
end

describe AMQP::Events::Event, ' as created event' do
  subject { AMQP::Events::Event.create self, 'TestEvent' }

  its(:name) { should == :TestEvent }
  its(:subscribers) { should be_empty }

  it_should_behave_like 'event'
end

describe AMQP::Events::ExternalEvent, ' class' do
  subject { AMQP::Events::ExternalEvent }

  specify { should respond_to :create }

  it 'should hide its new method' do
    expect { subject.new 'Test' }.to raise_error NoMethodError
  end

  context 'creating external Events' do
    it 'impossible to create without :routing' do
      expect { AMQP::Events::Event.create self, 'TestEvent', transport: @transport }.
              to raise_error /Unable to create ExternalEvent .* without routing/
    end

    it 'impossible to create without :transport' do
      expect { AMQP::Events::Event.create self, 'TestEvent', routing: 'routing' }.
              to raise_error /Unable to create ExternalEvent .* without transport/
    end

    it 'unless host exposes #transport' do
      def transport
        'some transport'
      end
      expect { AMQP::Events::Event.create self, 'TestEvent', routing: 'routing' }.
              to_not raise_error
    end
  end

end

describe AMQP::Events::ExternalEvent, ' as created event' do
  before { @transport = mock('transport').as_null_object } # Needed by ExternalEvent to set up subscription
  subject { AMQP::Events::Event.create self, 'TestEvent', routing: 'routing', transport: @transport }

  specify { should be_an AMQP::Events::ExternalEvent }
  specify { should respond_to :transport }
  its(:transport) { should_not be_nil }
  its(:name) { should == :TestEvent }
  its(:subscribers) { should be_empty }

  it_should_behave_like 'event'

end

