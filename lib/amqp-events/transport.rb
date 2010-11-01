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
    #
    class AMQPTransport < Transport

      attr_accessor :root, :routes, :exchanges

      # New AMQP transport for ExternalEvents - uses existing (already established) AMQP connection.
      # Accepts obligatory *root* (of AMQP exchange hierarchy) and a list of known exchanges.
      # Exchanges can be given as a names list or Hash of 'name' => {options} pairs.
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

      # Adds new known exchange to Transport's set of exchanges
      #
      def add_exchange name, opts = {}
        type             = opts.delete(:type) || :topic # By default, topic exchange
        exchange         = @mq.__send__(type, "#{@root}.#{name}", opts)
        @exchanges[name] = exchange
      end

      private

      # Turns list of exchange names (possibly with exchange options) into {'name'=>Exchange} Hash
      def exchanges_from *args
        exchanges  = args.last.is_a?(Hash) ? args.pop.to_a : []
        exchanges  += args.map { |name| [name, {}] }
        exchanges.each { |name, opts| add_exchange name, opts }
      end
    end
  end
end
