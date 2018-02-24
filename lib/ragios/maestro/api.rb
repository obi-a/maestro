module Ragios
  module Maestro
    class Api
      def self.test(monitor)
        u = Ragios::Plugins::UptimeMonitor.new
        u.init(monitor)
        u.test_command?
        u.test_result
      end
    end
  end
end
