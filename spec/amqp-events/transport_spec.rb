require 'spec_helper'

# Noop unless AMQP::SpecHelper was included - helps to share examples between evented and non-evented groups
def done
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
      @subject.exchanges['log.fatal'].should be_an MQ::Exchange
      @subject.exchanges['log.fatal'].type.should == :topic
      done
    end

    it 'adds new known exchange by name and options' do
      subject
      @subject.add_exchange 'fanout', type: 'fanout'
      @subject.exchanges.should have_key 'fanout'
      @subject.exchanges['fanout'].should be_an MQ::Exchange
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
      @subject.exchanges['fanout'].should be_an MQ::Exchange
      @subject.exchanges['fanout'].type.should == :fanout
      @subject.exchanges.should have_key 'log.fatal'
      @subject.exchanges['log.fatal'].should be_an MQ::Exchange
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
      @subject.exchanges['fanout'].should be_an MQ::Exchange
      @subject.exchanges['fanout'].type.should == :fanout
      @subject.exchanges.should have_key 'log.fatal'
      @subject.exchanges['log.fatal'].should be_an MQ::Exchange
      @subject.exchanges['log.fatal'].type.should == :topic
      @subject.exchanges.size.should == @num_exchanges
      @subject.exchanges.size.should == @num_exchanges
      done(0.1)
    end

    it 'raises error attempting to add undeclared exchange by name and options'
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
    log_exchange = subject.exchanges['log'].should_not be_nil
    log_exchange.name.should == 'test.log'
    log_exchange.type.should == :topic
    log_exchange.key.should == 'test.log'
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

  end
end

