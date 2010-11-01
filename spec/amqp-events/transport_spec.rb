require 'spec_helper'

def done
  #noop unless AMQP::SpecHelper was included - helps to share examples between evented and non-evented groups
end


shared_examples_for 'AMQP Transport' do

  it_should_behave_like 'Transport interface'

  its(:root) { should == 'test'; done }
  its(:exchanges) { should be_a Hash; done }
  its(:routes) { should be_empty; done }

  context '#add_exchange' do
    it 'Adds new known exchange by name' do
      subject.add_exchange 'exchange1'
      @subject.exchanges.should have_key 'exchange1'
      @subject.exchanges['exchange1'].should be_an MQ::Exchange
      done
    end

    it 'Adds new known exchange by name and options' do
      subject.add_exchange 'exchange2', type: 'fanout'
      @subject.exchanges.should have_key 'exchange2'
      @subject.exchanges['exchange2'].should be_an MQ::Exchange
      @subject.exchanges['exchange2'].type.should == :fanout
      done
    end
  end

  it 'should create new route when subscribed to'
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

  it_should_behave_like 'Transport interface'
end

describe AMQP::Events::AMQPTransport do

  it 'raises error if AMQP connection not established' do
    expect { described_class.new 'test' }.
        to raise_error /Unable to create AMQPTransport without active AMQP connection/
  end

  context 'inside active AMQP event loop' do
    include AMQP::Spec

    # Put your broker options into amqp.yml or set them explicitly here
    default_options AMQP_OPTS if defined? AMQP_OPTS

    # Creates actively evaluated subject
    active_subject { described_class.new 'test' }

    it_should_behave_like 'AMQP Transport'

    context 'with list of known exchanges given as a Hash' do
      active_subject { described_class.new 'test', 'system' => {}, 'data' => {}, 'log' => {}, 'system.command' => {} }

      it_should_behave_like 'AMQP Transport'

      its(:exchanges) { should have(4).exchanges; done }
    end

    context 'with list of known exchanges given as a names list' do
      active_subject { described_class.new 'test', 'system', 'data', 'log', 'system.command' }

      it_should_behave_like 'AMQP Transport'

      its(:exchanges) { should have(4).exchanges; done }
    end

    context 'with list of known exchanges given as a mixed list' do
      active_subject { described_class.new 'test', 'system', 'data', 'log' => {}, 'system.command' => {} }

      it_should_behave_like 'AMQP Transport'

      its(:exchanges) { should have(4).exchanges; done }
    end

  end
end

