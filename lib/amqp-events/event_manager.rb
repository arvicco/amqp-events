require 'amqp-events/external_event'

module AMQP
  module Events

    # Exposes external Events (received via transport) as its own local Events
    # *EventManager* encapsulates interface to external Events. It is used by Participant to:
    # * emit Events (for general use or for specific <groups of> other Participants)
    # * subscribe to Events (both external and internal)
    #
    class EventManager
      include AMQP::Events

      attr_accessor :transport

      def initialize(transport)
        @transport = transport
      end

    end
  end
end
