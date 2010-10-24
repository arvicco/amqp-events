#require 'spec_helper'
require_relative '../lib/amqp-events/events'
module EventsTest
  describe AMQP::Events, ' when running Second Change Event Example' do
    before { @clock = SecondChangeEvent::Clock.new }
    let(:messages) { [] }

    it 'should replicate results of C# example' do
      @n = 0
      $stdout.should_receive(:puts) { |msg| messages << msg; true }.at_least(10).times

#        #// Create the display and tell it to subscribe to the clock just created
      dc = SecondChangeEvent::DisplayClock.new
      dc.Subscribe(@clock)

      #// Create a Log object and tell it to subscribe to the clock
      lc = SecondChangeEvent::LogClock.new
      lc.Subscribe(@clock)

      #// Get the clock started
      @clock.Run(1)

      messages.count { |msg| msg =~/Current Time:/ }.should be_between 10, 11
      messages.count { |msg| msg =~/Logging to file:/ }.should be_between 10, 11
      messages.count { |msg| msg =~/Wow! Second passed!:/ }.should be_between 1, 2
    end

  end
end # module AMQPEventsTest

# This is a reproduction of "The Second Change Event Example" from:
# http://www.akadia.com/services/dotnet_delegates_and_events.html
# Now I need to change it into a test suite somehow...
module SecondChangeEvent
#  /* ======================= Event Publisher =============================== */

#  Our subject -- it is this class that other classes will observe. This class publishes one event:
#  SecondChange. The observers subscribe to that event.
  class Clock
    include AMQP::Events

    event :DeciSecondChange
    event :SecondChange

    # Set the clock running, it will raise an event for each new MILLI second!
    # With timeout for testing
    def Run(timeout=nil)
      start = Time.now
      while !timeout || timeout > Time.now - start do
        time = Time.now

        # If the (centi)second has changed, notify the subscribers
        # MilliSecondChange(self, time) if time.usec/1000 != @millisec # Doesn't work, Windows timer is ~ 15 msec
        DeciSecondChange(self, time) if time.usec/100_000 != @decisec
        SecondChange(self, time) if time.sec != @sec

        # Update the state
        @decisec = time.usec/100_000
        @sec = time.sec
      end
    end
  end

#  /* ======================= Event Subscribers =============================== */

  # An observer. DisplayClock subscribes to the clock's events.
  # The job of DisplayClock is to display the current time
  class DisplayClock
    # Given a clock, subscribe to its SecondChange event
    def Subscribe(theClock)
      # Calling SecondChange without parameters returns the Event object itself
      theClock.DeciSecondChange += proc { |*args| TimeHasChanged(*args) } # subscribing with a proc
      theClock.SecondChange.subscribe do |theClock, ti| # subscribing with block
        puts "Wow! Second passed!: #{ti.hour}:#{ti.min}:#{ti.sec}"
      end
    end

    #// The method that implements the delegated functionality
    def TimeHasChanged(theClock, ti)
      puts "Current Time: #{ti.hour}:#{ti.min}:#{ti.sec}"
    end
  end

  # A second subscriber whose job is to write to a file
  class LogClock

    def Subscribe(theClock)
      theClock.DeciSecondChange += method :WriteLogEntry # subscribing with a Method name
    end

    # This method should write to a file, but we just write to the console to see the effect
    def WriteLogEntry(theClock, ti)
      puts "Logging to file: #{ti.hour}:#{ti.min}:#{ti.sec}"
      # Code that logs to file goes here...
    end
  end
end
