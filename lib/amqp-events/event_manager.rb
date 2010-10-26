require 'mq'

module AMQP
  module Events

    # Exposes external Events (received via transport) as its own local Events:
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
