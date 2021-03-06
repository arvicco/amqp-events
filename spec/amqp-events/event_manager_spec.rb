require 'spec_helper'

describe AMQP::Events::EventManager, " as class" do
  subject { described_class }

  it_behaves_like 'evented class'

#  its(:instance_events) { should include :ExternalEventReceived}

end

describe AMQP::Events::EventManager, " when initialized" do
  before { @transport ||= mock('transport').as_null_object }
  subject { described_class.new @transport }

  it_behaves_like 'evented object'
  specify { should respond_to :transport }
  its(:transport) { should == @transport }

  it "should allow external events to be defined" do
    res = subject.event :ExternalBar, routing: '#.bar.#'
    res.should be_an AMQP::Events::ExternalEvent
  end

  context 'with a mix of external and internal Events' do
    before do
      @event_manager = described_class.new @transport
      @event_manager.event :Foo
      @event_manager.event :ExternalBar, routing: '#.bar.#'
    end
    subject { @event_manager }

    its(:events) { should have_key :Foo }
    its(:events) { should have_key :ExternalBar }

    context 'any of its defined external Events' do
      subject { @event_manager.ExternalBar }
      specify {should be_an AMQP::Events::ExternalEvent}
      it_behaves_like 'event'
    end

    context 'any of its defined internal Events' do
      subject { @event_manager.Foo }
      specify {should be_an AMQP::Events::Event}
      it_behaves_like 'event'
    end
  end

  context 'subscribing to EventManager`s Events' do
    it "should allow objects to subscribe to its internal Events (without engaging Transport)" do
      @transport.should_not_receive :subscribe
      event = subject.subscribe(:Burp) { |route, data| }
      event.should be_an AMQP::Events::Event
    end

    it "should allow objects to subscribe to external Events (through Transport)" do
      @transport.should_receive(:subscribe).with '#.log.#'
      event = subject.event(:LogEvent, routing: '#.log.#').subscribe(:my_log) { |route, data|  }
      event.should be_an AMQP::Events::ExternalEvent
    end
  end
end