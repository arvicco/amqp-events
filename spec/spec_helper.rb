require 'bundler'
Bundler.setup
Bundler.require :test

require 'amqp-events'
require 'pathname'
require 'shared_examples'

BASE_PATH = Pathname.new(__FILE__).dirname + '..'

#Spec::Runner.configure do |config|
#  # == Mock Framework
#  #
#  # RSpec uses it's own mocking framework by default. If you prefer to
#  # use mocha, flexmock or RR, uncomment the appropriate line:
#  #
#  # config.mock_with :mocha
#  # config.mock_with :flexmock
#  # config.mock_with :rr
#end

def subscribers_to_be_called(num, event = subject)
  @counter = 0

  event.subscribers.should have(num).subscribers
  event.listeners.should have(num).listeners

  event.fire "data" # fire Event, sending "data" to subscribers
  @counter.should == num
end

def should_be_defined_event(object=subject, name)
  object.should respond_to name.to_sym
  object.should respond_to "#{name}=".to_sym
  object.events.should include name.to_sym
  object.events.should_not include name.to_s
  object.class.instance_events.should include name.to_sym
  object.class.instance_events.should_not include name.to_s
  object.send(name.to_sym).should be_kind_of AMQP::Events::Event
end

def define_subscribers
  def self.subscriber_method(*args)
    args.should == ["data"]
    @counter += 1
  end

  @subscriber_proc = proc do |*args|
    args.should == ["data"]
    @counter += 1
  end
end
