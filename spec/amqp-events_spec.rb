require 'spec_helper'

class EmptyTestClass
  include AMQPEvents::Events
end

class TestClassWithEvents
  include AMQPEvents::Events

  event :Bar
  event :Baz
end

shared_examples_for 'evented object' do
end

module AMQPEventsTest
  describe EmptyTestClass, ' that includes AMQPEvents::Events and is just instantiated' do
    subject { EmptyTestClass }

    specify { should respond_to :instance_events }
    its(:instance_events) { should be_empty }
  end

  describe EmptyTestClass, ' when instantiated' do
    subject { EmptyTestClass.new }

    it_should_behave_like 'evented object'

    specify { should respond_to :events }
    its(:events) { should be_empty }
    its(:events) { should be_a Hash }

    context ' when manipulated' do
      it 'should create events on instance' do
        subject.event :Blah
        subject.events.should include :Blah
      end
    end
  end

  describe TestClassWithEvents, ' (predefined) that includes AMQPEvents::Events' do
    subject { TestClassWithEvents }

    specify { should respond_to :instance_events }
    its(:instance_events) { should include :Bar }
    its(:instance_events) { should include :Baz }
  end

  describe TestClassWithEvents, ' when instantiated' do

    it_should_behave_like 'evented object'

    specify { should respond_to :events }
    its(:events) { should be_a Hash }
    its(:events) { should_not be_empty }
    its(:events) { should have_key :Bar }
    its(:events) { should have_key :Baz }

    it 'should create events on instance' do
      subject.event :Blah
      subject.events.should include :Blah
    end
  end
end # module AMQPEventsTest

