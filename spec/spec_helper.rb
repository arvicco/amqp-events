require 'bundler'
Bundler.setup
Bundler.require :test

require 'amqp-events'
require 'pathname'
require 'shared_examples'

BASE_PATH = Pathname.new(__FILE__).dirname + '..'

amqp_config = File.dirname(__FILE__) + '/amqp.yml'

if File.exists? amqp_config
  class Hash
    def symbolize_keys
      self.inject({}) { |result, (key, value)|
        new_key = key.is_a?(String) ? key.to_sym : key
        new_value = value.is_a?(Hash) ? value.symbolize_keys : value
        result[new_key] = new_value
        result
      }
    end
  end

  AMQP_OPTS = YAML::load_file(amqp_config).symbolize_keys[:test]
end

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

# Makes 'subject' actively evaluated instead of default lazy evaluation
# in order to use evaluated subject multiple times in one example, use *@subject*
def active_subject &block
  define_method(:subject){ @subject = block.call}
end
