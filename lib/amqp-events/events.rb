module AMQPEvents
  module Events
    class SubscriberTypeError < TypeError
    end

    # TODO: Mutexes to synchronize @subscribers update ?
    # http://github.com/snuxoll/ruby-event/blob/master/lib/ruby-event/event.rb
    # TODO: Meta-methods that allow Events to fire on method invocations:
    # http://github.com/nathankleyn/ruby_events/blob/85f8e6027fea22e9d828c91960ce2e4099a9a52f/lib/ruby_events.rb
    # TODO: Add exception handling and subscribe/unsubscribe notifications:
    # http://github.com/matsadler/rb-event-emitter/blob/master/lib/events.rb
    class Event

      attr_reader :name, :subscribers

      def initialize(name)
        @name = name
        @subscribers = {}
      end

      # You can subscribe anything callable to the event, such as lambda/proc,
      # method(:method_name), attached block or a custom Handler. The only requirements,
      # it should respond to a #call and accept arguments given to Event#fire.
      #
      # Please keep in mind, if you attach a block to #subscribe without a name, you won't
      # be able to unsubscribe it later. However, if you give #subscribe a name and attached block,
      # you'll be able to unsubscribe using this name
      #
      # :call-seq:
      #   event.subscribe( proc{|*args| "Subscriber 1"}, method(:method_name)) {|*args| "Unnamed subscriber block" }
      #   event.subscribe("subscription_name") {|*args| "Named subscriber block" }
      #   event += method(:method_name)  # C# compatible syntax, just without useless "delegates"
      #
      def subscribe(*subscribers, &block)
        if block and subscribers.size == 1 and not subscribers.first.respond_to? :call
          # Arguments must be subscription block and its given name
          @subscribers[subscribers.first] = block
        else
          # Arguments must be a list of subscribers
          (subscribers + [block]).flatten.compact.each do |subscriber|
            if subscriber.respond_to? :call
              @subscribers[subscriber] = subscriber
            else
              raise Events::SubscriberTypeError.new "Handler #{subscriber.inspect} does not respond to #call"
            end
          end
        end
        self # This allows C#-like syntax : my_event -= subscriber
      end

      alias_method :+, :subscribe

      def unsubscribe(*subscribers)
        (subscribers).flatten.compact.each do |subscriber|
          @subscribers.delete(subscriber) if @subscribers[subscriber]
        end
        self # This allows C#-like syntax : my_event -= subscriber
      end

      alias_method :-, :unsubscribe
      alias_method :remove, :unsubscribe

      def fire(*args)
        @subscribers.each do |key, subscriber|
          subscriber.call *args
        end
      end

      alias_method :call, :fire

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
    end

    def events
      @events ||= self.class.instance_events.inject({}){|hash, name| hash[name]=Event.new(name); hash}
    end

    def event(*args)
      self.class.event(*args)
    end

    # Once included into a class/module, gives this module .event macros for declaring events
    def self.included(host)

      host.instance_exec do
        def instance_events
          @instance_events ||= []
        end

        def event (name)

          instance_events << name.to_sym
          # Defines instance method that has the same name as the Event being declared.
          # Calling it without arguments returns Event object itself
          # Calling it with block adds unnamed subscriber for Event
          # Calling it with arguments fires the Event
          # Such a messy interface provides some compatibility with C# events behavior
          define_method name do |*args, &block|
            events[name] ||= Event.new(name)
            if args.empty?
              if block
                events[name].subscribe &block
              else
                events[name]
              end
            else
              events[name].fire(*args)
            end
          end

          # Needed to support C#-like syntax : my_event -= subscriber
          define_method "#{name}=" do |event|
            if event.kind_of? Event
              events[name] = event
            else
              raise Events::SubscriberTypeError.new "Attempted assignment #{event.inspect} is not an Event"
            end
          end
        end
      end

    end
  end
end
