module Ragios
  module ZMQ
    class Subscriber < Base
      attr_reader :topic

      def initialize(options)
        @topic = options.fetch(:topic)
        super(options.merge(socket: :zmq_subscriber))
        @handler = options.fetch(:handler)
        @socket.subscribe(@topic)
      end

      def run
        loop do
          event = @socket.read_multipart.last
          async.handle_message(event)
        end
      end

      def handle_message(event)
        @handler.call(event)
        Ragios.log_event(self, "received", event)
      end
    end
  end
end