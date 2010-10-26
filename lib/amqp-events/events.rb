module AMQP
  module Events

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

    # object#unsubscribe(:Event) is a sugar-coat for object.Event#unsubscribe
    def unsubscribe(event, *args, &block)
      raise HandlerError.new "Unable to unsubscribe, there is no event #{event}" unless events[event.to_sym]
      events[event.to_sym].unsubscribe(*args, &block)
    end

    alias_method :listen, :subscribe
    alias_method :remove, :unsubscribe

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
