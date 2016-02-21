#  Usage:
#  monitor = {
#    monitor: "My Website",
#    url: "http://mysite.com",
#    every: "5m",
#    via: "hipchat",
#    room: "xyz"
#    plugin: "url_monitor"
#  }

module Ragios
  module Notifier
    class Hipchat

      def initialize(monitor)
        @token = ENV['HIPCHAT_TOKEN']
        @monitor = monitor
        @connection = Excon.new(ENV['HIPCHAT_API_HOST'])
        raise "A Room Name must be provided for the HipChat notifier in #{@monitor[:monitor]} monitor" if @monitor[:room].nil?
      end

      def failed(test_result)
        message = new_message("#{@monitor[:monitor]} JUST FAILED TEST!  Created on: #{Time.now.to_s}", "red")
        post(message)
      end

      def resolved(test_result)
        message = new_message("ISSUE RESOLVED  #{@monitor[:monitor]}  PASSED! Created on: #{Time.now.to_s}", "green")
        post(message)
      end

      def post(message)
        @connection.post(
          headers: {"Authorization" => "Bearer #{@token}", "Content-Type" => "application/json"},
          path: "/v2/room/#{@monitor[:room]}/notification",
          body: message.to_json
        )
      end

      def new_message(msg, color)
        {
          color: color,
          message: msg,
          notify: false,
          message_format: "text"
        }
      end
    end
  end
end
