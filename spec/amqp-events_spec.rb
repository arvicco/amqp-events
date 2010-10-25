require 'spec_helper'

class EmptyTestClass
  include AMQP::Events
end

class TestClassWithEvents
  include AMQP::Events

  event :Bar
  event :Baz
end

shared_examples_for 'evented class' do
  specify { should respond_to :instance_events }
  its(:instance_events) { should be_an Array }
end

shared_examples_for 'evented object' do
  specify { should respond_to :events }
  its(:events) { should be_a Hash }
end

module EventsTest
  describe EmptyTestClass, ' that includes AMQPEvents::Events and is just instantiated' do
    subject { EmptyTestClass }

    it_should_behave_like 'evented class'
    its(:instance_events) { should be_empty }

  end

  describe EmptyTestClass, ' when instantiated' do
    subject { EmptyTestClass.new }

    it_should_behave_like 'evented object'
    its(:events) { should be_empty }

    context 'creating new (class-wide) Events' do
      it 'should create events on instance' do
        subject.event :Blah
        subject.events.should include :Blah
      end
    end
  end

  describe TestClassWithEvents, ' (predefined) that includes AMQPEvents::Events' do
    subject { TestClassWithEvents }

    it_should_behave_like 'evented class'
    its(:instance_events) { should include :Bar }
    its(:instance_events) { should include :Baz }

    it 'should create new events' do
      subject.event :Foo
      subject.instance_events.should include :Foo
    end
  end

  describe TestClassWithEvents, ' when instantiated' do

    it_should_behave_like 'evented object'
    its(:events) { should have_key :Bar }
    its(:events) { should have_key :Baz }

    context 'creating new (class-wide) Events' do
      it 'should create events on instance' do
        subject.event :Blah
        subject.events.should include :Blah
        # object effectively defines new Event for all similar instances... Should it be allowed?
        subject.class.instance_events.should include :Blah

#      @sub1 = TestClassWithEvents.new
#      p class << subject
#         p instance_methods - Object.methods
#         p methods - Object.methods
#         self
#      end.instance_events
#      p @sub1.class.instance_events
#      p @sub1.class.instance_methods - Object.methods
#      p @sub1.class.methods - Object.methods
      end
    end

    context "subscribing to object's Event" do
      before { @bar_counter = 0 }

      it 'allows anyone to add block subscribers/listeners (multiple syntax)' do
        subject.events[:Bar].subscribe(:bar1) { |*args| args.should == ["data"]; @bar_counter += 1 }
        subject.Bar.subscribe(:bar2) { |*args| args.should == ["data"]; @bar_counter += 1 }
        subject.Bar.listen(:bar3) { |*args| args.should == ["data"]; @bar_counter += 1 }

        subject.Bar.subscribers.should have(3).subscribers
        subject.Bar.listeners.should have(3).listeners

        subject.Bar.fire "data" # fire Event, sending "data" to subscribers
        @bar_counter.should == 3
      end

      it 'allows anyone to add method subscribers/listeners (multiple syntax)' do
        def self.bar_count(*args)
          args.should == ["data"]
          @bar_counter += 1
        end

        subject.events[:Bar].subscribe(:bar1, method(:bar_count))
        subject.Bar.subscribe(:bar2, method(:bar_count))
        subject.Bar.listen(:bar3, method(:bar_count))
        subject.Bar.listen(method(:bar_count))
        subject.Bar += method(:bar_count)

        subject.Bar.subscribers.should have(5).subscribers
        subject.Bar.listeners.should have(5).listeners

        subject.Bar.fire "data" # fire Event, sending "data" to subscribers
        @bar_counter.should == 5
      end

      it 'allows anyone to add proc subscribers/listeners (multiple syntax)' do
        bar_count = proc do |*args|
          args.should == ["data"]
          @bar_counter += 1
        end

        subject.events[:Bar].subscribe(:bar1, bar_count)
        subject.Bar.subscribe(:bar2, bar_count)
        subject.Bar.subscribe(:bar3, &bar_count)
        subject.Bar.subscribe bar_count
        subject.Bar.subscribe &bar_count
        subject.Bar.listen bar_count
        subject.Bar += bar_count

        subject.Bar.subscribers.should have(7).subscribers
        subject.Bar.listeners.should have(7).listeners

        subject.Bar.fire "data" # fire Event, sending "data" to subscribers
        @bar_counter.should == 7
      end

      it "allows you t mix subscribers"

    end
  end
end # module EventsTest

