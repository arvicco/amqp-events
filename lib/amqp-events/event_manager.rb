require 'mq'

module AMQP
  module Events

    # Exposes external Events (received via transport) as its own local Events
    # (essentially, EventProxy?)
    class EventManager
      include AMQP::Events

      attr_accessor :transport

      def initialize(transport)
        @transport = transport
      end

      # You can subscribe anything callable to the event, such as lambda/proc,
      # method(:method_name), attached block or a custom Handler. The only requirements,
      # it should respond to a #call and accept arguments given to Event#fire.
      #
      # You can give optional name to your subscriber. If you do, you can later
      # unsubscribe it using this name. If you do not give subscriber a name, it will
      # be auto-generated using its #name method and uuid.
      #
      # You can unsubscribe your subscriber later, provided you know its name.
      #
      # :call-seq:
      #   event.subscribe(:event_name, "subscriber_name", proc{|*args| "Subscriber 1"})
      #   event.subscribe("subscriber_name", method(:method_name))
      #   event.subscribe(method(:method_name) # Implicit subscriber name == :method_name
      #   event.subscribe("subscriber_name") {|*args| "Named subscriber block" }
      #   event += method(:method_name)  # C# compatible syntax, just without useless "delegates"
      #
#      def subscribe(*args, &block)
#        subscriber = block ? block : args.pop
#        name = args.empty? ? generate_subscriber_name(subscriber) : args.first
#
#        raise HandlerError.new "Handler #{subscriber.inspect} does not respond to #call" unless subscriber.respond_to? :call
#        raise HandlerError.new "Handler name #{name} already in use" if @subscribers.has_key? name
#        @subscribers[name] = subscriber
#
#        self # This allows C#-like syntax : my_event += subscriber
#      end
#
#      alias_method :listen, :subscribe
#
#      def subscribe(routing='#', &block
#
#      end
    end
  end
end