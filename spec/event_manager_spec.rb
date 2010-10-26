require 'spec_helper'

describe AMQP::Events::EventManager, " as class" do
  subject { described_class }

  it_should_behave_like 'evented class'

#  its(:instance_events) { should include :ExternalEventReceived}

  it "should do something else" do
    pending

    #To change this template use File | Settings | File Templates.
    true.should == false
  end
end

describe AMQP::Events::EventManager, " when initialized" do
  before {@transport ||= mock 'transport'}
  subject { described_class.new @transport }

  it_should_behave_like 'evented object'
  specify { should respond_to :transport }
  its(:transport) { should_not be nil }

  it "should allow objects to subscribe to its internal Events (without engaging Transport)" do
    event = subject.subscribe(:Burple){|key, data| p key, data}
    event.should be_an AMQP::Events::Event
    @transport.should_not_receive :subscribe
  end

  it "should allow external events to be defined" do
    res = subject.event :ExternalBar, routing: '#.bar.#'
    res.should be_an AMQP::Events::ExternalEvent
  end

  it "should allow objects to subscribe to external Events (through Transport)" do
    @transport.should_receive :subscribe
    event = subject.subscribe(:LogEvent, routing: '#.log.#'){|key, data| p key, data}
    event.should be_an AMQP::Events::ExternalEvent
    p subject.events
    p subject.class.instance_events
  end
end