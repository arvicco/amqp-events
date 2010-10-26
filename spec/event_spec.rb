require 'spec_helper'

describe AMQP::Events::Event do
  subject { AMQP::Events::Event }

  it 'should hide its new method' do
    expect{ subject.new 'Test'}.to raise_error /Blah/
  end

  context 'with created test event' do
    subject { AMQP::Events::Event.create 'TestEvent' }

    its(:name) { should == :TestEvent }
    its(:subscribers) { should be_empty }

    it_should_behave_like 'event'
  end
end

