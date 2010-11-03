require 'spec_helper'

# Test Mock for actual Transport (AMQPTransport)
class MockTransport
  def initialize
    @subscriptions = {}
  end

  def subscribe(routing, &block)
    @subscriptions[routing] = block
  end

  def mock_data(routing, data)
    @subscriptions[routing].call(routing, data)
  end
end

describe AMQP::Events::ExternalEvent, ' class' do
  subject { AMQP::Events::ExternalEvent }

  specify { should respond_to :create }

  it 'should hide its new method' do
    expect { subject.new 'Test' }.to raise_error NoMethodError
  end

  context 'creating external Events' do
    it 'impossible to create without :routing' do
      expect { AMQP::Events::Event.create self, 'TestEvent', transport: 'transport' }.
              to raise_error /Unable to create ExternalEvent .* without routing/
    end

    it 'impossible to create without :transport' do
      expect { AMQP::Events::Event.create self, 'TestEvent', routing: 'routing' }.
              to raise_error /Unable to create ExternalEvent .* without transport/
    end

    it 'unless host exposes #transport' do
      def transport
        mock 'some transport'
      end

      expect { AMQP::Events::Event.create self, 'TestEvent', routing: 'routing' }.
              to_not raise_error
    end

    it 'should NOT subscribe with transport upon creation' do
      @transport = MockTransport.new
      @transport.should_not_receive(:subscribe)
      AMQP::Events::Event.create self, 'TestEvent', routing: 'routing', transport: @transport
    end
  end

end

describe AMQP::Events::ExternalEvent, ' as created event' do
  before { @transport = MockTransport.new } # Needed by ExternalEvent to set up subscription
  subject { AMQP::Events::Event.create self, 'TestEvent', routing: 'routing', transport: @transport }

  specify { should be_an AMQP::Events::ExternalEvent }
  specify { should respond_to :transport }
  its(:transport) { should_not be_nil }
  its(:name) { should == :TestEvent }
  its(:subscribers) { should be_empty }

  it_behaves_like 'event'


  context 'adding subscribers/observers' do
    it 'subscribes with transport when it adds first observer' do
      @transport.should_receive(:subscribe) do |routing, &block|
        routing.should == 'routing'
        block.should be_a Proc
      end
      subject.subscribe(:subscriber1) { |data| data.should == 'data' }
    end
  end

  context 'with 1 active subscriber' do
    before { subject.subscribe(:subscriber1) { |data| data.should == 'data' } }

    it 'DOES NOT subscribe with transport when adding more observers' do
      @transport.should_not_receive(:subscribe)
      subject.subscribe(:subscriber2) { |data| data.should == 'data' }
      subject.subscribe(:subscriber3) { |data| data.should == 'data' }
    end

    it 'should fire when transport receives data at requested routing' do
      subject.should_receive(:fire).with('routing', 'data').once
      @transport.mock_data('routing', 'data')
    end

    it 'should unsubscribe transport when last subscriber unsubscribes' do
      @transport.should_receive(:unsubscribe).with('routing')
      subject.unsubscribe(:subscriber1)
    end
  end

  context 'with 2 active subscribers' do
    before do
      subject.subscribe(:subscriber1) { |data| data.should == 'data' }
      subject.subscribe(:subscriber2) { |data| data.should == 'data' }
    end

    it 'should NOT unsubscribe transport when one subscriber unsubscribes, but there are others left' do
      @transport.should_not_receive(:unsubscribe)
      subject.unsubscribe(:subscriber1)
    end

    it 'should unsubscribe transport when last subscriber unsubscribes' do
      @transport.should_receive(:unsubscribe).with('routing')
      subject.unsubscribe(:subscriber1)
      subject.unsubscribe(:subscriber2)
    end
  end
end

