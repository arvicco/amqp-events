require 'spec_helper'

# Noop unless AMQP::SpecHelper was included - helps to share examples between evented and non-evented groups
def done timeout=nil
end

# Shorthand for MQ.exchange_type invocation
def exchange name, opts
  MQ.__send__((opts[:type] || :topic).to_sym, name, opts)
end

EXCHANGE_HIERARCHY = {'test.system'    => {},
                      'test.data'      => {},
                      'test.log'       => {},
                      'test.log.error' => {},
                      'test.log.fatal' => {},
                      'test.fanout'    => {type: 'fanout'}}

shared_examples_for 'AMQP Transport' do

  it_behaves_like 'Transport interface'

  its(:root) { should == 'test'; done }
  its(:exchanges) { should be_a Hash; done }
  its(:routes) { should be_empty; done }

  context '#add_exchange' do
    it 'adds new known (topic) exchange by name' do
      subject
      @subject.add_exchange 'log.fatal'
      @subject.exchanges.should have_key 'log.fatal'
      @subject.exchanges['log.fatal'].name.should == 'test.log.fatal'
      @subject.exchanges['log.fatal'].type.should == :topic
      done
    end

    it 'adds new known exchange by name and options' do
      subject
      @subject.add_exchange 'fanout', type: 'fanout'
      @subject.exchanges.should have_key 'fanout'
      @subject.exchanges['fanout'].name.should == 'test.fanout'
      @subject.exchanges['fanout'].type.should == :fanout
      done
    end

    it 'does not change state re-adding already added exchanges' do
      # amqp_before
      subject
      @subject.add_exchange 'log.fatal'
      @subject.add_exchange 'fanout', type: 'fanout'
      @num_exchanges = @subject.exchanges.size

      # example
      expect { @subject.add_exchange 'log.fatal' }.to_not raise_error
      expect { @subject.add_exchange 'log.fatal', type: :topic }.to_not raise_error
      expect { @subject.add_exchange 'log.fatal', type: 'topic' }.to_not raise_error
      expect { @subject.add_exchange 'fanout', type: 'fanout' }.to_not raise_error

      @subject.exchanges.should have_key 'fanout'
      @subject.exchanges['fanout'].name.should == 'test.fanout'
      @subject.exchanges['fanout'].type.should == :fanout
      @subject.exchanges.should have_key 'log.fatal'
      @subject.exchanges['log.fatal'].name.should == 'test.log.fatal'
      @subject.exchanges['log.fatal'].type.should == :topic
      @subject.exchanges.size.should == @num_exchanges
      done
    end

    it 'raises error attempting to add known exchange with different type/options' do
      # amqp_before
      subject
      @subject.add_exchange 'log.fatal'
      @subject.add_exchange 'fanout', type: 'fanout'
      @num_exchanges = @subject.exchanges.size

      # example
      expect { @subject.add_exchange 'fanout' }.
          to raise_error /Unable to add exchange 'fanout' with opts {:type=>:topic/
      expect { @subject.add_exchange 'fanout', durable: true }.
          to raise_error /Unable to add exchange 'fanout' with opts {:type=>:topic/
      expect { @subject.add_exchange 'log.fatal', type: :topic, durable: true }.
          to raise_error /Unable to add exchange 'log.fatal' with opts {:type=>:topic/

      @subject.exchanges.should have_key 'fanout'
      @subject.exchanges['fanout'].name.should == 'test.fanout'
      @subject.exchanges['fanout'].type.should == :fanout
      @subject.exchanges.should have_key 'log.fatal'
      @subject.exchanges['log.fatal'].name.should == 'test.log.fatal'
      @subject.exchanges['log.fatal'].type.should == :topic
      @subject.exchanges.size.should == @num_exchanges
      @subject.exchanges.size.should == @num_exchanges
      done(0.1)
    end

    it 'raises error attempting to add exchange that does not exist at broker' do
      pending 'it DOES blow up, but a little bit later - leaving @exchanges in inconsistent state :('
      # amqp_before
      subject
      @num_exchanges = @subject.exchanges.size

      # example
      expect { @subject.add_exchange 'unknown' }.
          to raise_error /Unable to add exchange 'unknown' with opts {:type=>:topic/
      expect { @subject.add_exchange 'unknown', type: :topic, durable: true }.
          to raise_error /Unable to add exchange 'log.fatal' with opts {:type=>:topic/

      @subject.exchanges.should have_key 'fanout'
      @subject.exchanges['fanout'].name.should == 'test.fanout'
      @subject.exchanges['fanout'].type.should == :fanout
      @subject.exchanges.should have_key 'log.fatal'
      @subject.exchanges['log.fatal'].name.should == 'test.log.fatal'
      @subject.exchanges['log.fatal'].type.should == :topic
      @subject.exchanges.size.should == @num_exchanges
      @subject.exchanges.size.should == @num_exchanges
      done(1)
    end
  end

  it 'should create new route when subscribed to'
end


shared_examples_for 'AMQP Transport with pre-defined exchanges' do
  its(:exchanges) { should have(4).exchanges; done }

  it 'has all pre-defined exchanges added' do
    exchanges = subject.exchanges
    exchanges.should have_key 'system'
    exchanges.should have_key 'data'
    exchanges.should have_key 'log'
    exchanges.should have_key 'log.error'
    done
  end

  it 'has log exchange with expected characteristics' do
    log_exchange = subject.exchanges['log']
    log_exchange.should_not be_nil
    log_exchange.name.should == 'test.log'
    log_exchange.type.should == :topic
    log_exchange.key.should be_nil
    log_exchange.opts.should == {:type=>:topic, :passive=>true}
    log_exchange.mq.should be_an MQ
    log_exchange.proper.should be_an MQ::Exchange
    done
  end
end

shared_examples_for 'Transport interface' do
  # Transport interface supports following methods:
  # #publish(routing, message):: publish to a requested routing a message (in routing-specific format)
  # #subscribe(routing, &block):: subscribe given block to a requested routing
  # #unsubscribe(routing):: cancel subscription to specific routing

  specify { should respond_to :subscribe; done }
  specify { should respond_to :unsubscribe; done }
  specify { should respond_to :publish; done }

  describe '#subscribe' do
    it 'accepts routing and subscriber block' do
      subject.subscribe('test.route') { |*args|}
      expect { subject.subscribe() }.to raise_error
      expect { subject.subscribe('test.route') }.to raise_error
      expect { subject.subscribe() { |*args|} }.to raise_error
      done
    end
  end

  describe '#unsubscribe' do
    it 'accepts routing' do
      subject.unsubscribe('test.route')
      expect { subject.unsubscribe() }.to raise_error
      done
    end
  end

  describe '#publish' do
    it 'accepts routing and any number of other arguments' do
      expect { subject.publish() }.to raise_error
      subject.publish('test.route', "string", :symbol, 1, [1, '2', :three], {me: 2}, Object.new)
      done
    end
  end
end

describe AMQP::Events::Transport do
  subject { described_class.new }

  it_behaves_like 'Transport interface'
end

describe AMQP::Events::AMQPTransport do

  it 'raises error if AMQP connection not established' do
    expect { described_class.new 'test' }.
        to raise_error /Unable to create AMQPTransport without active AMQP connection/
  end

  context 'with SpecHelper' do
    include AMQP::SpecHelper

    it 'raises error attempting to add exchange that does not exist at broker' do
      expect {
        amqp do
      # amqp_before
      subject
      @num_exchanges = @subject.exchanges.size

      # example
      expect { @subject.add_exchange 'unknown' }.
          to_not raise_error /Unable to add exchange 'unknown' with opts {:type=>:topic/
#      expect { @subject.add_exchange 'unknown', type: :topic, durable: true }.
#          to raise_error /Unable to add exchange 'log.fatal' with opts {:type=>:topic/

      done(0.5)
      end
      }.   to raise_error #/Unable to add exchange 'unknown' with opts {:type=>:topic/

    end

  end

  context 'inside active AMQP event loop' do
    include AMQP::Spec

    before(:all) do
      # Declare all Hierarchy exchanges
      EXCHANGE_HIERARCHY.each { |name, opts| exchange(name, opts) }
      puts `rabbit ctl list_exchanges`
      done
    end

    after(:all) do
      EXCHANGE_HIERARCHY.each do |name, opts|
        exchange(name, opts).delete #(nowait: false)
      end
      done(1) { puts `rabbit ctl list_exchanges` }
    end

    # Put your broker options into amqp.yml or set them explicitly here
    default_options AMQP_OPTS if defined? AMQP_OPTS

    # Creates actively evaluated subject
    active_subject { described_class.new 'test' }

    it_behaves_like 'AMQP Transport'

    context 'with list of known exchanges given as a Hash' do
      active_subject { described_class.new 'test', 'system' => {}, 'data' => {}, 'log' => {}, 'log.error' => {} }

      it_behaves_like 'AMQP Transport'
      it_behaves_like 'AMQP Transport with pre-defined exchanges'
    end

    context 'with list of known exchanges given as a names list' do
      active_subject { described_class.new 'test', 'system', 'data', 'log', 'log.error' }

      it_behaves_like 'AMQP Transport'
      it_behaves_like 'AMQP Transport with pre-defined exchanges'
    end

    context 'with list of known exchanges given as a mixed list' do
      active_subject { described_class.new 'test', 'system', 'data', 'log' => {}, 'log.error' => {} }

      it_behaves_like 'AMQP Transport'
      it_behaves_like 'AMQP Transport with pre-defined exchanges'
    end

    context 'testing AMQP internals' do

      it 'fails, raising error if undeclared exchange requested with passive: true', failing: true do
        pending 'it demonstrated that error is raised, even though invalid MQ::Exchange is blithely created'
        #AMQP.logging = true
        p AMQP.conn.connected?
        @mq          = MQ.new
        p @mq.topic "undeclared", passive: true, nowait: false
        done #(0.1) { AMQP.logging = false }
      end
    end
  end
end

