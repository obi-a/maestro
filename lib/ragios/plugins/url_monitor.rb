# Plugin: Monitors a URL by sending a http GET request to it
# the test PASSES if it gets a HTTP 200, 301 or 302 Response status code from the http request

module Ragios
  module Plugin

    class UrlMonitor
      attr_reader :test_result
      attr_reader :url
      attr_reader :connection
      attr_reader :options

      def init(monitor)
        raise "A url must be provided for url_monitor in #{monitor[:monitor]} monitor" if monitor[:url].nil?
        @url = monitor[:url]
        @connection = Excon.new(@url)
        @options = {
          expects: [200, 301, 302],
          method: :get,
          idempotent: true
        }
        @options[:retry_limit] = monitor[:retry_limit] || 3
        @options[:connect_timeout] = monitor[:connect_timeout] || 60
      end

      def test_command?
        response = @connection.request(@options)
        @test_result = {"url_monitor" => "success", "result" => response.status}
        return true
      rescue => e
        @test_result = {"url_monitor" => "failure", "result" => e.message}
        return false
      end
    end
  end
end
