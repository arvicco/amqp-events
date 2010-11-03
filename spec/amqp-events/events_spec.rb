require 'spec_helper'

class TestClassWithoutEvents
  include AMQP::Events
end

class TestClassWithEvents
  include AMQP::Events

  event :Bar
  event :Baz
end

describe TestClassWithoutEvents, ' that includes AMQPEvents::Events' do
  subject { TestClassWithoutEvents }

  its(:instance_events) { should be_empty }
  it_behaves_like 'evented class'
end

describe TestClassWithoutEvents, ' when instantiated' do

  its(:events) { should be_empty }
  it_behaves_like 'evented object'

  context "when Event is defined for this object, it" do
    before do
      @object = TestClassWithoutEvents.new
      @object.event :Bar
    end
    subject { @object.Bar }
    it_behaves_like 'event'
  end
end

describe TestClassWithEvents, ' that includes AMQPEvents::Events and pre-defines events Bar/Baz' do
  subject { TestClassWithEvents }

  its(:instance_events) { should include :Bar }
  its(:instance_events) { should include :Baz }

  it_behaves_like 'evented class'

  context 'creating new Events' do
    before { @events_size = subject.instance_events.size }

    it 'should create events on instance, with Symbol as a name' do
      res = subject.event :Foo
      res.should == :Foo
      should_be_defined_event(subject.new, :Foo)
      subject.instance_events.size.should == @events_size + 1
    end

    it 'should create events on instance, with String as a name' do
      res = subject.event 'Boo'
      res.should == :Boo
      should_be_defined_event(subject.new, :Boo)
      subject.instance_events.size.should == @events_size + 1
    end

    it 'should not redefine already defined events' do
      res = subject.event :Bar
      res.should == :Bar
      should_be_defined_event(subject.new, :Bar)
      subject.instance_events.size.should == @events_size
      res = subject.event 'Bar'
      res.should == :Bar
      should_be_defined_event(subject.new, :Bar)
      subject.instance_events.size.should == @events_size
    end

    context 'when defined Event is redefined with different type (ExternalEvents instead of Event)' do
      it 'should raise error if existing Event is redefined with different options' do
        expect {subject.event :Bar, routing: 'routing', transport: 'transport'}.
                to raise_error /Unable to redefine Event Bar with options {:routing=>"routing", :transport=>"transport"}/
        should_be_defined_event(subject.new, :Bar)
        subject.new.Bar.should be_an AMQP::Events::Event
        subject.instance_events.size.should == @events_size
        expect {subject.event 'Bar', routing: 'routing', transport: 'transport'}.
                to raise_error /Unable to redefine Event Bar with options {:routing=>"routing", :transport=>"transport"}/
        should_be_defined_event(subject.new, :Bar)
        subject.new.Bar.should be_an AMQP::Events::Event
        subject.instance_events.size.should == @events_size
      end
    end
  end
end

describe TestClassWithEvents, ' when instantiated' do

  it_behaves_like 'evented object'

  its(:events) { should have_key :Bar }
  its(:events) { should have_key :Baz }

  context "its pre-defined Events" do
    before do
      @object = TestClassWithEvents.new
    end
    subject { @object.Bar }
    it_behaves_like 'event'
  end
end # TestClassWithEvents, ' when instantiated'

