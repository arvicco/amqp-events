require 'mq'

module AMQP
  module Events

    # Represent Transport that can be used to subscribe to external Events and propagate your own Events.
    #
    # *Transport* encapsulates external messaging middleware (such as AMQP library). Its role is to send data
    # to external destination (as defined by Routing) and deliver data received from external destination as
    # instructed. It is used by EventManager to send serialized Events and subscribe to external Events.
    #
    # Transport interface supports following methods:
    # #publish(routing, message):: publish to a requested routing a message (in routing-specific format)
    # #subscribe(routing, &block):: subscribe given block to a requested routing
    # #unsubscribe(routing):: cancel subscription to specific routing
    #
    class Transport

      def subscribe routing, &block
        raise TransportError.new "Transport unable to subscribe: Routing #{routing} invalid" unless routing
        raise TransportError.new "Transport unable to subscribe: Subscriber #{subscriber} invalid" unless block
      end

      def unsubscribe routing
        raise TransportError.new "Transport unable to unsubscribe: Routing #{routing} invalid" unless routing

      end

      def publish routing, *args
        raise TransportError.new "Transport unable to publish: Routing #{routing} invalid" unless routing

      end
    end

    # AMQPTransport is an implementation of Transport interface as related to AMQP protocol/library.
    # It encapsulates knowledge about AMQP exchanges and queues and converts Routing requested by
    # EventManager into actual combination of AMQP ‘exchange/queue name’ + ‘topic routing’.
    #
    # TODO:  Where exactly does it get knowledge of actual exchange names, formats, etc from?
    # TODO: Abstract away actual AMQP library into MessagingMiddleware abstraction? (for 0mq, fake adapters)
    #
    class AMQPTransport < Transport

      # AMQPTransport:: Exchange is a proxy/decorator for MQ::Exchange, exposing some of its
      # hidden state and adding functionality
      class Exchange

        attr_reader :proper, :opts, :mq

        def initialize mq, name, opts
          @mq     = mq
          @opts   = opts
          @proper = MQ::Exchange.new mq, opts[:type], name, opts
        end

        # Routing all unknown method calls to exchange proper
        def method_missing method, *args
          @proper.__send__(method, *args)
        end
      end

      attr_accessor :root, :routes, :exchanges

      # New AMQP transport for ExternalEvents - uses AMQP connection (it should already be established).
      # Accepts obligatory *root* (of AMQP exchange hierarchy) and a list of known exchanges.
      # Exchanges can be given as a names list or Hash of 'name' => {options} pairs.
      #
      def initialize root, *args
        @root      = root
        raise TransportError.new "Unable to create AMQPTransport with root #{root.inspect}" unless @root
        raise TransportError.new "Unable to create AMQPTransport without active AMQP connection" unless AMQP.conn && AMQP.conn.connected?
        @mq        = MQ.new
        @routes    = {}
        @exchanges = {}
        add_exchanges_from *args
        super()
      end

      # Adds new exchange to a set of exchanges known to this Transport,
      # TODO: make sure only EXISTING exchanges are added and none created (for consistency of existing hierarchy)
      #
      def add_exchange name, opts = {}
        exchange_name        = @root ? "#{@root}.#{name}" : "#{name}"
        exchange_opts        = {type: :topic, passive: true}.merge(symbolize(opts))

        if @exchanges[name]
          if @exchanges[name].opts != exchange_opts
            raise TransportError.new "Unable to add exchange '#{name}' with opts #{exchange_opts.inspect}"
          end
          @exchanges[name]
        else
          @exchanges[name] = Exchange.new @mq, exchange_name, exchange_opts
        end
      end

      private

      # Given a list of exchange names (possibly with exchange options),
      # adds all of them to this Transport
      #
      def add_exchanges_from *args
        exchanges  = args.last.is_a?(Hash) ? args.pop.to_a : []
        exchanges  += args.map { |name| [name, {}] }
        exchanges.each { |name, opts| add_exchange name, opts }
      end

      # Turns both keys and (String) values of hash into Symbols
      def symbolize hash
        hash.inject({}) do |result, (key, value)|
          result[key.to_sym] = value.is_a?(String) ? value.to_sym : value
          result
        end
      end
    end
  end
end
