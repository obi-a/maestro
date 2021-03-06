module Ragios
  module Notifications
    class NotifyWorker
      include Celluloid

      def perform(event, monitor, test_result, notifier)
        event_details = {
          monitor_id: monitor[:_id],
          state: event,
          time: Time.now.utc,
          type: "event",
          event_type: "monitor.notification",
          monitor: monitor,
          test_result: test_result,
          notifier: notifier_name(notifier)
        }

        notifier.send(event, test_result) if notifier.respond_to?(event)

        occurred = {notified: event, via: notifier_name(notifier)}
        pusher.async.log_event!(
          event_details.merge(event: occurred)
        )
      rescue Exception => exception
        occurred = {"notifier error" => exception.message}
        pusher.async.log_event!(
          event_details.merge(event: occurred)
        )
        raise exception
      end

    private

      def pusher
        Ragios::Events::Pusher.new
      end

      def notifier_name(notifier)
        notifier.class.name.split('::').last
      end
    end
  end
end
