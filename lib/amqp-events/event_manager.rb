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
      def subscribe(event, *args, &block)
        opts = args.last.kind_of?(Hash) ? args.pop : {}

        if opts[:routing]
          defined_event = super event, *args, &block
          @transport.subscribe(opts[:routing]) do |routing, data| defined_event.fire(routing, data) end
          defined_event
          # Clearing @transport subscriptions if all the event listeners unsubscribed?
          # Maybe I still need ExternalEvents?
          # this looks like EventManager is trying too hard to help Event do its job -
          # setting subscriber blocks and such...
          # Maybe I should pass through to Event for it to do its job?
          # This way, both external and internal Events should be treated as equals by EventManager
        else
          super event, *args, &block
        end
      end

      alias_method :listen, :subscribe

    end
  end
end
