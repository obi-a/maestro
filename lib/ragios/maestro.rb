module Ragios
  module Maestro
    class Api
      def self.init
        @@connectionsCache = {}
      end

      def self.create(params)
        headless = false
        browser_name = "firefox"
        browser = Hercules::Maestro::Browser.new(params[:url], browser_name, headless)
        @@connectionsCache.merge!({params[:connection_id] => browser})
        {ok: true}
      end

      def self.exists(params)
        key = params[:connection_id]
        browser = @@connectionsCache[key]
        result = browser.exists? params[:query]
        {connection_id: params[:connection_id], query: params[:query], exists: result }
      end
    end
  end
end