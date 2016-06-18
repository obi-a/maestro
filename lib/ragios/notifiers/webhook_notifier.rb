module Ragios
  module Notifier
    class WebhookNotifier
      def initialize(monitor)
        raise "A webhook_url is required" unless monitor[:webhook_url]
        @monitor = monitor
        @connection = Excon.new(monitor[:webhook_url])
      end

      def failed(test_result)
        message = result("failed", test_result)
        puts message.inspect
        #post(message)
      end
      def resolved(test_result)
        message = result("resolved", test_result)
        puts message.inspect
        #post(message)
      end

      def result(event, test_result)
        {
          event: event,
          ragiosid: @monitor[:_id],
          monitor: @monitor,
          test_result: test_result
        }
      end
      def post(message)
        @connection.post(
          headers: {"Content-Type" => "application/json"},
          body: message.to_json
        )
      end
    end
 end
end
