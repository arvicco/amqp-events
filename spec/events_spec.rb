require 'spec_helper'

class TestClassWithoutEvents
  include AMQP::Events
end

class TestClassWithEvents
  include AMQP::Events

  event :Bar
  event :Baz
end

describe TestClassWithoutEvents, ' that includes AMQPEvents::Events and is just instantiated' do
  subject { TestClassWithoutEvents }

  its(:instance_events) { should be_empty }
  it_should_behave_like 'evented class'
end

describe TestClassWithoutEvents, ' when instantiated' do

  its(:events) { should be_empty }
  it_should_behave_like 'evented object'

  context 'creating new (class-wide) Events' do
    it 'should create events on instance, with Symbol as a name' do
      res = subject.event :Blurp
      res.should be_an AMQP::Events::Event
      subject.events.should include :Blurp
      # object effectively defines new Event for all similar instances... Should it be allowed?
      subject.class.instance_events.should include :Blurp
    end

    it 'should create events on instance, with String as a name' do
      res = subject.event 'Blurp'
      res.should be_an AMQP::Events::Event
      subject.events.should include :Blurp
      subject.class.instance_events.should include :Blurp
      subject.events.should_not include 'Blurp'
      subject.class.instance_events.should_not include 'Blurp'
    end
  end

  context "when Event is defined for this object, it" do
    before do
      @object = TestClassWithoutEvents.new
      @object.event :Bar
    end
    subject { @object.Bar }
    it_should_behave_like 'event'
  end
end

describe TestClassWithEvents, ' that includes AMQPEvents::Events and pre-defines events Bar/Baz' do
  subject { TestClassWithEvents }

  it_should_behave_like 'evented class'
  its(:instance_events) { should include :Bar }
  its(:instance_events) { should include :Baz }

  it 'should create new events' do
    subject.event :Foo
    subject.instance_events.should include :Foo
  end

  it 'should not redefine already defined events' do
    events_size = subject.instance_events.size
    subject.event :Bar
    subject.instance_events.should include :Bar
    subject.instance_events.size.should == events_size
    subject.event 'Bar'
    subject.instance_events.should include :Bar
    subject.instance_events.size.should == events_size
  end
end

describe TestClassWithEvents, ' when instantiated' do

  it_should_behave_like 'evented object'
  its(:events) { should have_key :Bar }
  its(:events) { should have_key :Baz }

  context 'creating new (class-wide) Events' do
    it 'should not redefine already defined events' do
      events_size = subject.events.size
      res = subject.event :Baz
      res.should be_an AMQP::Events::Event
      subject.events.should include :Baz
      subject.events.size.should == events_size

      subject.event 'Baz'
      subject.events.size
      subject.events.should include :Baz
      subject.events.should_not include 'Baz'
      subject.class.instance_events.should include :Baz
      subject.class.instance_events.should_not include 'Baz'
      subject.events.size.should == events_size
    end
  end

  context "its pre-defined Events" do
    before do
      @object = TestClassWithEvents.new
    end
    subject { @object.Bar }
    it_should_behave_like 'event'
  end
end # TestClassWithEvents, ' when instantiated'

