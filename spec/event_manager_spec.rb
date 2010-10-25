require 'spec_helper'

describe AMQP::Events::EventManager, " as class" do
  subject { described_class }

  it_should_behave_like 'evented class'

#  its(:instance_events) { should include :ExternalEventReceived}

  it "should do something" do
    pending

    #To change this template use File | Settings | File Templates.
    true.should == false
  end
end

describe AMQP::Events::EventManager, " when initialized" do
  subject { described_class.new mock 'transport' }

  it_should_behave_like 'evented object'
  specify { should respond_to :transport }
  its(:transport) { should_not be nil }

  it "should allow objects to subscribe for external Events" do

    event = subject.subscribe('#.log.#'){|key, data| p key, data}
    event.should be_an AMQP::Events::Event
    p object.events


  end
end