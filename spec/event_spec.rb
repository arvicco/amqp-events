require 'spec_helper'

describe AMQP::Events::Event do
  subject { AMQP::Events::Event.new 'TestEvent' }

  its(:name) { should == :TestEvent }
  its(:subscribers) { should be_empty }

  it_should_behave_like 'event'
end

