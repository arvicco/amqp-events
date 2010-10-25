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

def subscribers_to_be_called(num)
  @counter = 0

  subject.Bar.subscribers.should have(num).subscribers
  subject.Bar.listeners.should have(num).listeners

  subject.Bar.fire "data" # fire Event, sending "data" to subscribers
  @counter.should == num
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
      end
    end

    context "#subscribe to object's Event" do

      it 'allows anyone to add block subscribers/listeners (multiple syntax)' do
        subject.events[:Bar].subscribe(:bar1) { |*args| args.should == ["data"]; @counter += 1 }
        subject.Bar.subscribe(:bar2) { |*args| args.should == ["data"]; @counter += 1 }
        subject.Bar.listen(:bar3) { |*args| args.should == ["data"]; @counter += 1 }

        subscribers_to_be_called 3
      end

      it 'allows anyone to add method subscribers/listeners (multiple syntax)' do
        def self.subscriber_method(*args)
          args.should == ["data"]
          @counter += 1
        end

        subject.events[:Bar].subscribe(:bar1, method(:subscriber_method))
        subject.Bar.subscribe(:bar2, method(:subscriber_method))
        subject.Bar.listen(:bar3, method(:subscriber_method))
        subject.Bar.listen(method(:subscriber_method))
        subject.Bar += method(:subscriber_method)

        subscribers_to_be_called 5
      end

      it 'allows anyone to add proc subscribers/listeners (multiple syntax)' do
        subscriber_proc = proc do |*args|
          args.should == ["data"]
          @counter += 1
        end

        subject.events[:Bar].subscribe(:bar1, subscriber_proc)
        subject.Bar.subscribe(:bar2, subscriber_proc)
        subject.Bar.subscribe(:bar3, &subscriber_proc)
        subject.Bar.subscribe subscriber_proc
        subject.Bar.subscribe &subscriber_proc
        subject.Bar.listen subscriber_proc
        subject.Bar += subscriber_proc

        subscribers_to_be_called 7
      end

      it "allows you to mix subscriber types for one Event" do
        def self.subscriber_method(*args)
          args.should == ["data"]
          @counter += 1
        end

        subscriber_proc = proc do |*args|
          args.should == ["data"]
          @counter += 1
        end

        subject.Bar.subscribe { |*args| args.should == ["data"]; @counter += 1 }
        subject.Bar += method :subscriber_method
        subject.Bar += subscriber_proc

        subscribers_to_be_called 3
      end

      it "raises exception if the given handler is not callable" do

        [:subscriber_symbol, 1, [1, 2, 3], {me: 2}].each do |args|
          expect { subject.Bar.subscribe(args) }.
                  to raise_error /Handler .* does not respond to #call/
          expect { subject.Bar.subscribe(:good_name, args) }.
                  to raise_error /Handler .* does not respond to #call/
          subscribers_to_be_called 0
        end
      end

      it "raises exception when adding handler with duplicate name" do
        subscriber_proc = proc do |*args|
          args.should == ["data"]
          @counter += 1
        end

        subject.Bar.listen(:bar1) { |*args| args.should == ["data"]; @counter += 1 }

        expect { subject.Bar.listen(:bar1) { |*args| args.should == ["data"]; @counter += 1 } }.
                to raise_error /Handler name bar1 already in use/
        expect { subject.Bar.listen(:bar1, subscriber_proc) }.
                to raise_error /Handler name bar1 already in use/
        subscribers_to_be_called 1
      end
    end #subscribe

    context "#unsubscribe from object's Event" do
      it "allows you to unsubscribe from Events by name" do
        def self.subscriber_method(*args)
          args.should == ["data"]
          @counter += 1
        end

        subscriber_proc = proc do |*args|
          args.should == ["data"]
          @counter += 1
        end

        subject.Bar.subscribe(:bar1) { |*args| args.should == ["data"]; @counter += 1 }
        subject.Bar.subscribe(:bar2, method(:subscriber_method))
        subject.Bar.subscribe(:bar3, subscriber_proc)

        subject.Bar.unsubscribe(:bar1)
        subject.Bar.unsubscribe(:bar2)
        subject.Bar.unsubscribe(:bar3)

        subscribers_to_be_called 0
      end

      it "raises exception if the name is unknown or wrong" do
        subscriber_proc = proc do |*args|
          args.should == ["data"]
          @counter += 1
        end

        subject.Bar.subscribe(subscriber_proc)

        expect { subject.Bar.unsubscribe(subscriber_proc) }.
                to raise_error /Unable to unsubscribe handler/
        expect { subject.Bar.unsubscribe('I-dont-know') }.
                to raise_error /Unable to unsubscribe handler I-dont-know/

        subscribers_to_be_called 1
      end
    end #unsubscribe
  end # TestClassWithEvents, ' when instantiated'
end # module EventsTest

