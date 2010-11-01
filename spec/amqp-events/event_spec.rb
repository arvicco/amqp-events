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