require 'amqp-events/event'

module AMQP
  module Events
    # Represent external Event that can be subscribed to (by subscribers/observers).
    # External means, it happens outside of this Ruby process, and is delivered through Transport.
    # When Transport informs ExternalEvent that it happened (someplace else),
    # ExternalEvent 'fires' and makes sure that all subscribers are called.
    #
    # Any evented object (host) that defines ExternalEvent should provide it with transport either
    # explicitly (via option :transport) or expose its own #transport.
    #
    class ExternalEvent < Event
      attr_reader :transport

      def initialize(host, name, opts)
        @routing = opts[:routing]
        @transport = opts[:transport] || host.transport rescue nil
        raise EventError.new "Unable to create ExternalEvent #{name.inspect} without routing" unless @routing
        raise EventError.new "Unable to create ExternalEvent #{name.inspect} without transport" unless @transport
        super host, name
      end

      # Subscribe to external event... Uses @transport for actual subscription
      def subscribe(*args, &block)
        super *args, &block
        @transport.subscribe(@routing) {|routing, data| fire(routing, data) } if @subscribers.size == 1
        self # This allows C#-like syntax : my_event += subscriber
      end

      # Unsubscribe from external event... Cancels @transport subscription if no subscribers left
      def unsubscribe(name)
        super name
        @transport.unsubscribe(@routing) if @subscribers.empty?
        self # This allows C#-like syntax : my_event -= subscriber_name
      end
    end
  end
end