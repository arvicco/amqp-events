module AMQP
  module Events
    if RUBY_PLATFORM =~ /mingw|mswin|windows/ #Windows!
      require 'uuid'
      UUID = UUID
    else
      require 'em/pure_ruby' unless defined? EventMachine::UuidGenerator
      UUID = EventMachine::UuidGenerator
    end

    class HandlerError < TypeError
    end

    # TODO: Mutexes to synchronize @subscribers update ?
    # http://github.com/snuxoll/ruby-event/blob/master/lib/ruby-event/event.rb
    # TODO: Meta-methods that allow Events to fire on method invocations:
    # http://github.com/nathankleyn/ruby_events/blob/85f8e6027fea22e9d828c91960ce2e4099a9a52f/lib/ruby_events.rb
    # TODO: Add exception handling and subscribe/unsubscribe notifications:
    # http://github.com/matsadler/rb-event-emitter/blob/master/lib/events.rb
    class Event

      attr_reader :name, :subscribers
      alias_method :listeners, :subscribers

      def initialize(name)
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

      alias_method :listen, :subscribe
      alias_method :+, :subscribe

      # Unsubscribe existing subscriber by name
      def unsubscribe(name)
        raise HandlerError.new "Unable to unsubscribe handler #{name}" unless @subscribers.has_key? name
        @subscribers.delete(name)

        self # This allows C#-like syntax : my_event -= subscriber
      end

      alias_method :remove, :unsubscribe
      alias_method :-, :unsubscribe

      # TODO: make fire async: just fire and continue, instead of waiting for all subscribers to return,
      # as it is right now. AMQP callbacks and EM:Deferrable?
      def fire(*args)
        @subscribers.each do |key, subscriber|
          subscriber.call *args
        end
      end

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

#    class ExternalEvent < Events::Event
#      # redefines subscribe to subscribe to use @transport.subscribe and then redistribute
#      # received call to all @subscribers... Now, Event should know about @transport too... ugly
#      #
#    end

    def events
      @events ||= self.class.instance_events.inject({}) { |hash, name| hash[name]=Event.new(name); hash }
    end

    def event(name)
      sym_name = name.to_sym
      self.class.event(sym_name)
      events[sym_name] ||= Event.new(sym_name)
    end

    # object#subscribe(:Event) is a sugar-coat for object.Event#subscribe
    def subscribe(event, *args, &block)
      event(event).subscribe(*args, &block)
    end

    alias_method :listen, :subscribe

# Once included into a class/module, gives this module .event macros for declaring events
    def self.included(host)

      host.instance_exec do
        def instance_events
          @instance_events ||= []
        end

        def event (name)
          sym_name = name.to_sym

          unless instance_events.include? sym_name
            instance_events << sym_name
            # Defines instance method that has the same name as the Event being declared.
            # Calling it without arguments returns Event object itself
            # Calling it with block adds unnamed subscriber for Event
            # Calling it with arguments fires the Event
            # Such a messy interface provides some compatibility with C# events behavior
            define_method name do |*args, &block|
              events[sym_name] ||= Event.new(sym_name)
              if args.empty?
                if block
                  events[sym_name].subscribe &block
                else
                  events[sym_name]
                end
              else
                events[sym_name].fire(*args)
              end
            end

            # Needed to support C#-like syntax : my_event -= subscriber
            define_method "#{name}=" do |event|
              if event.kind_of? Event
                events[name.to_sym] = event
              else
                raise Events::SubscriberTypeError.new "Attempted assignment #{event.inspect} is not an Event"
              end
            end
          end
        end
      end

    end

  end
end
