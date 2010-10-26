module AMQP
  module Events

    # Represent Event that can be subscribed to (by subscribers/observers)
    # All subscribed observers will be called when this Event 'fires'.
    #
    # TODO: Mutexes to synchronize @subscribers update/event fire ?
    # http://github.com/snuxoll/ruby-event/blob/master/lib/ruby-event/event.rb
    # TODO: Meta-methods that allow Events to fire on method invocations:
    # http://github.com/nathankleyn/ruby_events/blob/85f8e6027fea22e9d828c91960ce2e4099a9a52f/lib/ruby_events.rb
    # TODO: Add exception handling and subscribe/unsubscribe notifications:
    # http://github.com/matsadler/rb-event-emitter/blob/master/lib/events.rb
    class Event

      class << self
        protected :new

        # Creates Event of appropriate subclass, depending on arguments
        def create *args, &block
          case args.size
            when 2
              # Plain vanilla Event
              Event.new *args, &block
            when 3
              # External Event (with Routing)
              ExternalEvent.new *args, &block
          end
        end
      end

      attr_reader :host, :name, :subscribers
      alias_method :listeners, :subscribers

      def initialize(host, name)
        @host = host
        @name = name.to_sym
        @subscribers = {}
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
      #   event.subscribe("subscriber_name", proc{|*args| "Subscriber 1"})
      #   event.subscribe("subscriber_name", method(:method_name))
      #   event.subscribe(method(:method_name) # Implicit subscriber name == :method_name
      #   event.subscribe("subscriber_name") {|*args| "Named subscriber block" }
      #   event += method(:method_name)  # C# compatible syntax, just without useless "delegates"
      #
      def subscribe(*args, &block)
        subscriber = block ? block : args.pop
        name = args.empty? ? generate_subscriber_name(subscriber) : args.first.to_sym

        raise HandlerError.new "Handler #{subscriber.inspect} does not respond to #call" unless subscriber.respond_to? :call
        raise HandlerError.new "Handler name #{name} already in use" if @subscribers.has_key? name
        @subscribers[name] = subscriber

        self # This allows C#-like syntax : my_event += subscriber
      end

      # Unsubscribe existing subscriber by name
      def unsubscribe(name)
        raise HandlerError.new "Unable to unsubscribe handler #{name}" unless @subscribers.has_key? name
        @subscribers.delete(name)

        self # This allows C#-like syntax : my_event -= subscriber
      end

      # TODO: make fire async: just fire and continue, instead of waiting for all subscribers to return,
      # as it is right now. AMQP callbacks and EM:Deferrable?
      def fire(*args)
        @subscribers.each do |key, subscriber|
          subscriber.call *args
        end
      end

      alias_method :listen, :subscribe
      alias_method :+, :subscribe
      alias_method :remove, :unsubscribe
      alias_method :-, :unsubscribe
      alias_method :call, :fire

      # Clears all the subscribers for a given Event
      def clear
        @subscribers.clear
      end

      def == (other)
        case other
          when Event
            super
          when nil
            @subscribers.empty?
          else
            false
        end
      end

      private
      def generate_subscriber_name(subscriber)
        "#{subscriber.respond_to?(:name) ? subscriber.name : 'subscriber'}-#{UUID.generate}".to_sym
      end
    end


    # Represent external Event that can be subscribed to (by subscribers/observers).
    # External means, it happens outside of this Ruby process, and is delivered through Transport.
    # When Transport informs ExternalEvent that it happened (someplace else),
    # ExternalEvent 'fires' and makes sure that all subscribers are called.
    #
    class ExternalEvent < Event
      attr_reader :transport

      def initialize(host, name, routing)
        @routing = routing
        super host, name
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
      #   event.subscribe("subscriber_name", proc{|*args| "Subscriber 1"})
      #   event.subscribe("subscriber_name", method(:method_name))
      #   event.subscribe(method(:method_name) # Implicit subscriber name == :method_name
      #   event.subscribe("subscriber_name") {|*args| "Named subscriber block" }
      #   event += method(:method_name)  # C# compatible syntax, just without useless "delegates"
      #
      def subscribe(*args, &block)
        super *args, &block
        @host.transport.subscribe(@routing) {|routing, data| fire(routing, data) } if @subscribers.size = 1
        self # This allows C#-like syntax : my_event += subscriber
      end

      #
      def unsubscribe(name)
        super name
        @host.transport.unsubscribe(@routing) if @subscribers.empty?
        self # This allows C#-like syntax : my_event -= subscriber_name
      end
    end
  end
end
