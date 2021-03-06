require 'spec_base.rb'

class OffRagios; end

module Ragios
  class OffPlugin; end
  module Plugins
    class GoodPlugin
      attr_reader :test_result
      def init(options); end
      def test_command?; end
    end

    class NoTestCmd
      attr_reader :test_result
      def init(options); end
    end

    class NoTestResult
      def init(options); end
      def test_command?; end
    end

    class NoInit
      attr_reader :test_result
      def test_command?; end
    end

    class Passing
      attr_reader :test_result
      def init(options); end
      def test_command?
        @test_result = {"This test" => "always passes"}
        return true
      end
    end

    class Failing
      attr_reader :test_result
      def init(options); end
      def test_command?
        @test_result = {"This test" => "always fails"}
        return false
      end
    end

    class Error
      attr_reader :test_result
      def init(options); end
      def test_command?
        raise "test_command? error"
      end
    end
  end
end

module Ragios
  class OffNotifier; end
  module Notifiers
    class GoodNotifier
      def init(monitor);end
      def failed(test_result);end
      def resolved(test_result);end
    end

    class OtherGoodNotifier
      def init(monitor);end
      def failed(test_result);end
      def resolved(test_result);end
    end

    class NoInit
      def failed(test_result);end
      def resolved(test_result);end
    end

    class NoFailed
      def init(monitor);end
      def resolved(test_result);end
    end

    class NoResolved
      def init(monitor);end
      def failed(test_result);end
    end
  end
end

describe Ragios::Monitors::GenericMonitor do
  describe "skip_extensions_creation" do
    context "when set to true" do
      it "creates a plugin and notifers" do
        options = {plugin: "good_plugin", via: "good_notifier"}
        # skip_extensions_creation defaults to false
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options)
        expect(generic_monitor.plugin).to be_a(Ragios::Plugins::GoodPlugin)
        expect(generic_monitor.notifiers).to include(a_kind_of(Ragios::Notifiers::GoodNotifier))
      end
    end
    context "when set to false" do
      it "does not create a plugin and notifers" do
        options = {}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, skip_extensions_creation = true)
        expect(generic_monitor.plugin).to be_nil
        expect(generic_monitor.notifiers).to be_nil
      end
      it "raises an exception on test_command?" do
        options = {}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, skip_extensions_creation = true)
        expect {generic_monitor.test_command?}.to raise_error(Ragios::PluginNotFound)
      end
    end
  end

  describe "#create" do
    context "when valid monitor options are provided" do
      it "persists a monitor in DB and schedules it with the scheduler" do
        monitor_opts = {
          monitor: "website",
          every:  "10m",
          via: ["good_notifier"],
          plugin: "good_plugin"
        }
        Celluloid.shutdown; Celluloid.boot
        receiver = Ragios::RecurringJobs::Receiver.new(skip_scheduler_creation = true)
        future = receiver.future.receive
        generic_monitor = Ragios::Monitors::GenericMonitor.create(monitor_opts)
        received = JSON.parse(future.value.first, symbolize_names: true)

        expect(generic_monitor.id).to eq(received[:monitor_id])
        expect(generic_monitor.interval).to eq(received[:interval])
        expect(received[:perform]).to eq("run_now_and_schedule")

        id = generic_monitor.id
        doc = Ragios.database.get_doc(id)
        expect(doc).to include(type: "monitor", _id: id, status_: 'active')
        expect(doc).to include(monitor_opts)
        Ragios.database.delete_doc!(id)
      end
    end
    context "when invalid monitor options are provided" do
      it "fails validation and raises an exception" do
        opts = {monitor: "monitor"}
        expect{Ragios::Monitors::GenericMonitor.create(opts)}.to raise_error(Ragios::PluginNotFound)
      end
    end
  end

  describe "#stop" do
    context "when the monitor exists" do
      it "stops the monitor" do
        database = Ragios.database

        monitor = {
          monitor: "website",
          every:  "10m",
          type: "monitor",
          status_: "active",
          created_at_: Time.now
        }
        monitor_id = SecureRandom.uuid
        database.create_doc monitor_id, monitor

        Celluloid.shutdown; Celluloid.boot
        receiver = Ragios::RecurringJobs::Receiver.new(skip_scheduler_creation = true)
        future = receiver.future.receive
        Ragios::Monitors::GenericMonitor.stop(monitor_id)
        received = JSON.parse(future.value.first, symbolize_names: true)
        expect(received).to eq(monitor_id: monitor_id, perform: "unschedule")
        saved = database.get_doc(monitor_id)
        expect(saved[:status_]).to eq("stopped")

        database.delete_doc!(monitor_id)
      end
    end
    context "when monitor is not found in the database" do
      it "raises a monitor not found exception" do
        expect{Ragios::Monitors::GenericMonitor.stop("not_found")}.to raise_error(Ragios::MonitorNotFound)
      end
    end
  end

  describe "#start" do
    context "when monitor exists" do
      context "when monitor is valid" do
        it "starts the monitor in the scheduler & updates the database" do
          Celluloid.shutdown; Celluloid.boot
          database = Ragios.database
          interval = "10m"
          monitor = {
            monitor: "website",
            every:  interval,
            type: "monitor",
            plugin: "good_plugin",
            via: "good_notifier",
            status_: "stopped",
            created_at_: Time.now
          }
          monitor_id = SecureRandom.uuid
          database.create_doc monitor_id, monitor

          receiver = Ragios::RecurringJobs::Receiver.new(skip_scheduler_creation = true)
          future = receiver.future.receive
          started = Ragios::Monitors::GenericMonitor.start(monitor_id)
          expect(started).to be_truthy
          received = JSON.parse(future.value.first, symbolize_names: true)
          expect(received).to eq(monitor_id: monitor_id,interval: interval, perform: "reschedule")
          saved = database.get_doc(monitor_id)
          expect(saved[:status_]).to eq("active")

          database.delete_doc!(monitor_id)
        end
      end
      context "when monitor is not valid" do
        it "fails validation and raises an exception" do
          database = Ragios.database
          monitor = {
            monitor: "website",
            every:  "10m",
            type: "monitor",
            status_: "stopped",
            created_at_: Time.now
          }
          monitor_id = SecureRandom.uuid
          database.create_doc monitor_id, monitor

          expect{ Ragios::Monitors::GenericMonitor.start(monitor_id) }.to raise_error(Ragios::PluginNotFound)
        end
      end
    end
    context "when monitor is not found" do
      it "raises a monitor not found exception" do
        expect{Ragios::Monitors::GenericMonitor.start("not_found")}.to raise_error(Ragios::MonitorNotFound)
      end
    end
  end

  describe "#delete" do
    context "when monitor exists" do
      it "deletes & unchedules the monitor and updates its status" do
        database = Ragios.database

        monitor = {
          monitor: "website",
          every:  "10m",
          type: "monitor",
          status_: "active",
          created_at_: Time.now
        }
        monitor_id = SecureRandom.uuid
        database.create_doc monitor_id, monitor

        Celluloid.shutdown; Celluloid.boot
        receiver = Ragios::RecurringJobs::Receiver.new(skip_scheduler_creation = true)
        future = receiver.future.receive
        Ragios::Monitors::GenericMonitor.delete(monitor_id)
        received = JSON.parse(future.value.first, symbolize_names: true)
        expect(received).to eq(monitor_id: monitor_id, perform: "unschedule")

        expect { database.get_doc(monitor_id) }.to raise_error(/not_found/)
      end
    end
    context "when monitor is not found" do
      it "raises a monitor not found exception" do
        expect{Ragios::Monitors::GenericMonitor.start("not_found")}.to raise_error(Ragios::MonitorNotFound)
      end
    end
  end

  describe "#update" do
    context "when valid options is provided" do
      context "when interval is updated" do
        it "reschedules the monitor with new interval" do
          database = Ragios.database

          monitor = {
            monitor: "website",
            every:  "30m",
            type: "monitor",
            plugin: "good_plugin",
            via: "good_notifier",
            status_: "stopped",
            created_at_: Time.now
          }
          monitor_id = SecureRandom.uuid
          database.create_doc monitor_id, monitor

          Celluloid.shutdown; Celluloid.boot
          receiver = Ragios::RecurringJobs::Receiver.new(skip_scheduler_creation = true)
          future = receiver.future.receive
          interval = "15m"
          updated_monitor = "updated monitor"
          updated = Ragios::Monitors::GenericMonitor.update(monitor_id, monitor: updated_monitor, every: interval)
          expect(updated).to be_truthy
          received = JSON.parse(future.value.first, symbolize_names: true)
          expect(received).to eq(monitor_id: monitor_id, interval: interval, perform: "reschedule")
          saved = database.get_doc(monitor_id)
          expect(saved).to include(monitor: updated_monitor, every: interval)
          database.delete_doc!(monitor_id)
        end
      end
      it "updates the monitor attributes" do
        expect(Ragios::Monitors::GenericMonitor).not_to receive(:reschedule)
        database = Ragios.database

        monitor = {
          monitor: "website",
          every: "30m",
          type: "monitor",
          plugin: "good_plugin",
          via: "good_notifier",
          status_: "stopped",
          created_at_: Time.now
        }
        monitor_id = SecureRandom.uuid
        database.create_doc monitor_id, monitor

        updated_monitor = "updated monitor"
        updated = Ragios::Monitors::GenericMonitor.update(monitor_id, monitor: updated_monitor)
        expect(updated).to be_truthy
        saved = database.get_doc(monitor_id)
        expect(saved).to include(monitor: updated_monitor)
        database.delete_doc!(monitor_id)
      end
    end
    context "when valid options are not provided" do
      context "when reserved attributes are provided in options" do
        it "raises a cannot update system settings exception" do
          database = Ragios.database

          monitor = {
            monitor: "website",
            every: "30m",
            type: "monitor",
            plugin: "good_plugin",
            via: "good_notifier",
            status_: "stopped",
            created_at_: Time.now
          }
          monitor_id = SecureRandom.uuid
          database.create_doc monitor_id, monitor
          updated_status = "active"
          [:type, :status_, :created_at_, :creation_timestamp_, :current_state_, :_id].each do |sys_setting|
            expect{ Ragios::Monitors::GenericMonitor.update(monitor_id, sys_setting => updated_status)}.to raise_error(
              Ragios::CannotEditSystemSettings
            )
          end
          database.delete_doc!(monitor_id)
        end
      end
      context "when updated monitor fails validation" do
        it "raises an exception" do
          database = Ragios.database

          monitor = {
            monitor: "website",
            every: "30m",
            type: "monitor",
            plugin: "good_plugin",
            via: "good_notifier",
            status_: "stopped",
            created_at_: Time.now
          }
          monitor_id = SecureRandom.uuid
          database.create_doc monitor_id, monitor
          updated_notifier = "not_found"
          expect{ Ragios::Monitors::GenericMonitor.update(monitor_id,via: updated_notifier)}.to raise_error(
            /Cannot Create notifier/
          )
          database.delete_doc!(monitor_id)
        end
      end
      context "when monitor not found" do
        it "raises a monitor not found exception" do
          expect{Ragios::Monitors::GenericMonitor.update("not_found",{})}.to raise_error(Ragios::MonitorNotFound)
        end
      end
    end
  end

  describe "#trigger_work" do
    context "when monitor exists" do
      it "triggers work in the scheduler" do
        database = Ragios.database
        interval = "10m"
        monitor = {
          monitor: "website",
          every:  interval,
          type: "monitor",
          plugin: "good_plugin",
          via: "good_notifier",
          status_: "stopped",
          created_at_: Time.now
        }
        monitor_id = SecureRandom.uuid
        database.create_doc monitor_id, monitor

        Celluloid.shutdown; Celluloid.boot
        receiver = Ragios::RecurringJobs::Receiver.new(skip_scheduler_creation = true)
        future = receiver.future.receive
        triggered = Ragios::Monitors::GenericMonitor.trigger(monitor_id)
        expect(triggered).to be_truthy
        received = JSON.parse(future.value.first, symbolize_names: true)
        expect(received).to eq(monitor_id: monitor_id, perform: "trigger_work")
      end
    end
    context "when monitor does not exist" do
      it "raises a monitor not found exception" do
        expect{Ragios::Monitors::GenericMonitor.trigger("not_found")}.to raise_error(Ragios::MonitorNotFound)
      end
    end
  end

  describe "#find" do
    before(:all) do

      @database = Ragios.database

      monitor = {
        monitor: "website",
        every:  "10m",
        type: "monitor",
        status_: "stopped",
        created_at_: Time.now
      }
      @monitor_with_state = "monitor_#{Time.now.to_i}"
      @database.create_doc @monitor_with_state, monitor

      @event = {
        monitor_id: @monitor_with_state,
        state: "failed",
        event: {winner: "chicken dinner"},
        time: Time.now.to_s,
        timestamp: Time.now.to_i,
        monitor: monitor,
        event_type: "monitor.test",
        type: "event"
      }
      @event_doc = "event_by_state_#{Time.now.to_i}"
      @database.create_doc @event_doc, @event

      monitor = {
        monitor: "other website",
        every:  "10m",
        type: "monitor",
        status_: "stopped",
        created_at_: Time.now
      }
      @other_monitor_with_no_state = "other_monitor_#{Time.now.to_i}"
      @database.create_doc @other_monitor_with_no_state, monitor

      monitor = {
        monitor: "other website",
        every:  "10m",
        status_: "stopped",
        created_at_: Time.now
      }
      @no_monitor_type = "no_monitor_type_#{Time.now.to_i}"
      @database.create_doc @no_monitor_type, monitor
    end
    context "when monitor with id exists" do
      context "when monitor has a current state" do
        before(:each) do
          @generic_monitor = Ragios::Monitors::GenericMonitor.find(@monitor_with_state, skip_extensions_creation = true)
        end
        it "returns the generic monitor with its most current state" do
          expect(@generic_monitor).to be_a(Ragios::Monitors::GenericMonitor)
          expect(@generic_monitor.state).to eq(@event[:state])
        end
        it "sets the generic_monitor with most current test_result" do
          expect(@generic_monitor.test_result).to eq(@event[:event])
        end
        it "sets the generic_monitor with most recent time_of_test" do
          expect(@generic_monitor.time_of_test).to eq(@event[:time])
        end
      end
      context "when monitor has no current state" do
        it "returns the generic monitor with default state (pending state)" do
          generic_monitor = Ragios::Monitors::GenericMonitor.find(@other_monitor_with_no_state, skip_extensions_creation = true)
          expect(generic_monitor).to be_a(Ragios::Monitors::GenericMonitor)
          expect(generic_monitor.state).to eq("pending")
        end
      end
      context "when monitor is not of type monitor" do
        it "raises a Ragios::MonitorNotFound exception" do
          expect { Ragios::Monitors::GenericMonitor.find(@no_monitor_type, skip_extensions_creation = true) }.to raise_error(
            Ragios::MonitorNotFound
          )
        end
      end
    end
    context "when monitor doesn't exist" do
      it "raises a Ragios::MonitorNotFound exception" do
        expect { Ragios::Monitors::GenericMonitor.find("not_found", skip_extensions_creation = true) }.to raise_error(
          Ragios::MonitorNotFound
        )
      end
    end
    after(:all) do
      @database.delete_doc! @monitor_with_state
      @database.delete_doc! @event_doc
      @database.delete_doc! @other_monitor_with_no_state
    end
  end
  describe "#build_extension" do
    context "when extension type is not found" do
      it "will raise a Ragios::UnIdentifiedExtensionType error" do
        expect{Ragios::Monitors::GenericMonitor.build_extension(:unknown, "good_notifier")}.to raise_error(
          Ragios::UnIdentifiedExtensionType, /Unidentified Extension Type unknown/
        )
      end
    end
    context "when extension is a notifier" do
      context "when extension is in the Ragios Module" do
        context "when extension is in the Notifier Module" do
          it "will build and return the notifier" do
            expect(Ragios::Monitors::GenericMonitor.build_extension(:notifier, "good_notifier")).to be_a(
              Ragios::Notifiers::GoodNotifier
            )
          end
          context "when notifier name is not a string" do
            it "will be converted to a string" do
              expect(Ragios::Monitors::GenericMonitor.build_extension(:notifier, :good_notifier)).to be_a(
                Ragios::Notifiers::GoodNotifier
              )
            end
          end
        end
      end
      context "when notifier is not in the Notifier Module" do
        it "will raise an error" do
          expect{Ragios::Monitors::GenericMonitor.build_extension(:notifier, "off_notifier")}.to raise_error(
            NameError, /Cannot Create notifier off_notifier/
          )
        end
      end
      context "when notifier is not in the Ragios Module" do
        it "will raise an error" do
          expect{Ragios::Monitors::GenericMonitor.build_extension(:notifier, "off_ragios")}.to raise_error(
            NameError, /Cannot Create notifier off_ragios/
          )
        end
      end
      context "when notifier is not found" do
        it "will raise an error" do
          expect{Ragios::Monitors::GenericMonitor.build_extension(:notifier, "not_found")}.to raise_error(
            NameError, /Cannot Create notifier not_found/
          )
        end
      end
    end
    context "when extension is a plugin" do
      context "when extension is in the Ragios module" do
        context "when plugin is in the Plugin module" do
          it "will build and return the plugin" do
            expect(Ragios::Monitors::GenericMonitor.build_extension(:plugin,"good_plugin")).to be_a(Ragios::Plugins::GoodPlugin)
          end
          context "when plugin name is not a string" do
            it "will be converted to a string" do
              expect(Ragios::Monitors::GenericMonitor.build_extension(:plugin, :good_plugin)).to be_a(Ragios::Plugins::GoodPlugin)
            end
          end
        end
        context "when plugin is not the Plugin module" do
          it "will raise an error" do
            expect{Ragios::Monitors::GenericMonitor.build_extension(:plugin, "off_plugin")}.to raise_error(
              NameError, /Cannot Create plugin off_plugin/
            )
          end
        end
      end
      context "when plugin is not in the Ragios Module" do
        it "will raise an error" do
          expect{Ragios::Monitors::GenericMonitor.build_extension(:plugin, "off_ragios")}.to raise_error(
            NameError, /Cannot Create plugin off_ragios/
          )
        end
      end
      context "when plugin is not found" do
        it "will raise an error" do
          expect{Ragios::Monitors::GenericMonitor.build_extension(:plugin, "not_found")}.to raise_error(
            NameError, /Cannot Create plugin not_found/
          )
        end
      end
    end
  end

  describe "#is_fixed" do
    it "calls push_event with resolved" do
      generic_monitor = Ragios::Monitors::GenericMonitor.new({_id: "monitor_id"}, true)
      expect(generic_monitor).to receive(:push_event).with("resolved")
      generic_monitor.is_fixed
    end
  end

  describe "#has_failed" do
    it "calls push_event with failed" do
      generic_monitor = Ragios::Monitors::GenericMonitor.new({_id: "monitor_id"}, true)
      expect(generic_monitor).to receive(:push_event).with("failed")
      generic_monitor.has_failed
    end
  end

  describe "#push_event" do
    it "pushes events to notifier" do
      Celluloid.shutdown; Celluloid.boot
      options = {_id: "monitor_id"}
      generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
      state = "resolved"
      receiver = Ragios::Notifications::Receiver.new
      future  = receiver.future.receive
      results = {
        monitor_id: "monitor_id",
        state: state,
        event: nil,
        time: nil,
        monitor: options,
        type: "event",
        event_type: "monitor.#{state}"
      }
      expect(generic_monitor.push_event(state)).to eq(results)
      received = JSON.parse(future.value.first, symbolize_names: true)
      expect(received).to eq(results)
    end
  end
  describe "State Transitions" do
    describe "#test_command?" do
      context "when monitor state transitions from pending to failed" do
        it "pushes a failed event to Notifier" do
          generic_monitor = Ragios::Monitors::GenericMonitor.new({
            plugin: "failing",
            via: "good_notifier"
          })
          expect(generic_monitor).to be_pending
          expect(generic_monitor).to receive(:push_event).with("failed")
          expect(generic_monitor.test_command?).to be_falsey
          expect(generic_monitor).to be_failed
          expect(generic_monitor.test_result).to eq({"This test" => "always fails"})
        end
      end
      context "when monitor state transitions from pending to passed" do
        it "does not push an event to Notifier" do
          generic_monitor = Ragios::Monitors::GenericMonitor.new({
            plugin: "passing",
            via: "good_notifier"
          })
          expect(generic_monitor).to be_pending
          expect(generic_monitor).not_to receive(:push_event)
          expect(generic_monitor.test_command?).to be_truthy
          expect(generic_monitor).to be_passed
          expect(generic_monitor.test_result).to eq({"This test" => "always passes"})
        end
      end
      context "when monitor state transitions from pending to error" do
        it "does not push an event to notifier" do
          generic_monitor = Ragios::Monitors::GenericMonitor.new({
            plugin: "error",
            via: "good_notifier"
          })
          expect(generic_monitor).to be_pending
          expect(generic_monitor).not_to receive(:push_event)
          expect{generic_monitor.test_command?}.to raise_error("test_command? error")
          expect(generic_monitor).to be_error
        end
      end
      context "when monitor state transitions from passed to error" do
        it "does not push an event to notifier" do
          generic_monitor = Ragios::Monitors::GenericMonitor.new({
            plugin: "error",
            via: "good_notifier"
          })
          generic_monitor.state = "passed"
          expect(generic_monitor).not_to receive(:push_event)
          expect{generic_monitor.test_command?}.to raise_error("test_command? error")
          expect(generic_monitor).to be_error
        end
      end
      context "when monitor state transitions from failed to error" do
        it "does not push an event to notifier" do
          generic_monitor = Ragios::Monitors::GenericMonitor.new({
            plugin: "error",
            via: "good_notifier"
          })
          generic_monitor.state = "failed"
          expect(generic_monitor).not_to receive(:push_event)
          expect{generic_monitor.test_command?}.to raise_error("test_command? error")
          expect(generic_monitor).to be_error
        end
      end
      context "when monitor state transitions from failed to failed" do
        it "does not push an event to notifier" do
          generic_monitor = Ragios::Monitors::GenericMonitor.new({
            plugin: "failing",
            via: "good_notifier"
          })
          generic_monitor.state = "failed"
          expect(generic_monitor).not_to receive(:push_event)
          expect(generic_monitor.test_command?).to be_falsey
          expect(generic_monitor).to be_failed
          expect(generic_monitor.test_result).to eq({"This test" => "always fails"})
        end
      end
      context "when monitor state transitions from passed to passed" do
        it "does not push an event to notifier" do
          generic_monitor = Ragios::Monitors::GenericMonitor.new({
            plugin: "passing",
            via: "good_notifier"
          })
          generic_monitor.state = "passed"
          expect(generic_monitor).not_to receive(:push_event)
          expect(generic_monitor.test_command?).to be_truthy
          expect(generic_monitor).to be_passed
          expect(generic_monitor.test_result).to eq({"This test" => "always passes"})
        end
      end
      context "when monitor state transitions from passed to failed" do
        it "pushes a failed event to Notifier" do
          generic_monitor = Ragios::Monitors::GenericMonitor.new({
            plugin: "failing",
            via: "good_notifier"
          })
          generic_monitor.state = "passed"
          expect(generic_monitor).to receive(:push_event).with("failed")
          expect(generic_monitor.test_command?).to be_falsey
          expect(generic_monitor).to be_failed
          expect(generic_monitor.test_result).to eq({"This test" => "always fails"})
        end
      end
      context "when monitor state transitions from failed to passed" do
        it "pushes a failed event to Notifier" do
          generic_monitor = Ragios::Monitors::GenericMonitor.new({
            plugin: "passing",
            via: "good_notifier"
          })
          generic_monitor.state = "failed"
          expect(generic_monitor).to receive(:push_event).with("resolved")
          expect(generic_monitor.test_command?).to be_truthy
          expect(generic_monitor).to be_passed
          expect(generic_monitor.test_result).to eq({"This test" => "always passes"})
        end
      end
    end
  end
  describe "#create_plugin" do
    context "when plugin is included in options" do
      context "when plugin defines test_result" do
        context "when plugin implements test_command" do
          context "when plugin implements init(options)" do
            it "creates the plugin" do
              options = {plugin: "good_plugin"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect(generic_monitor.create_plugin).to be_a(Ragios::Plugins::GoodPlugin)
              expect(generic_monitor.plugin).to be_a(Ragios::Plugins::GoodPlugin)
            end
          end
        end
      end
    end
    context "when plugin does not implement test_command?" do
      context "when plugin defines test_result" do
        context "when plugin is included in options" do
          context "when plugin implements init(options)" do
            it "raises a PluginTestCommandNotImplemented exception, plugin not is created" do
              options = {plugin: "no_test_cmd"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginTestCommandNotImplemented)
              expect(generic_monitor.plugin).to be_nil
            end
          end
        end
      end
    end
    context "when plugin does not define test_result" do
      context "when plugin implements test_command?" do
        context "when plugin is included in options" do
          context "when plugin implements init(options)" do
            it "raises a PluginTestResultNotDefined exception, plugin is not created" do
              options = {plugin: "no_test_result"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginTestResultNotDefined)
              expect(generic_monitor.plugin).to be_nil
            end
          end
        end
      end
    end
    context "when plugin does not implement init(options) method" do
      context "when plugin defines test_result" do
        context "when plugin implements test_command" do
          context "when plugin is included in options" do
            it "raises a PluginInitNotImplemented exception, plugin is not created" do
              options = {plugin: "no_init"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginInitNotImplemented)
              expect(generic_monitor.plugin).to be_nil
            end
          end
        end
      end
    end
    context "when there is no plugin in options" do
      it "raises a PluginNotFound exception, plugin is not created" do
        options = {}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginNotFound)
        expect(generic_monitor.plugin).to be_nil
      end
    end
    context "when plugin key in options is not a symbol" do
      it "raises a PluginNotFound exception, plugin is not created" do
        options = {"plugin" => "plugin" }
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginNotFound)
        expect(generic_monitor.plugin).to be_nil
      end
    end
  end

  describe "#create_notifiers" do
    context "when notifiers are not included in options" do
      it "raises a NotifierNotFound exception" do
        options = {}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierNotFound)
        expect(generic_monitor.notifiers).to be_nil
      end
    end
    context "when notifiers list is empty in options" do
      it "raises a NotifierNotFound exception" do
        options = {via: []}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierNotFound)
        expect(generic_monitor.notifiers).to be_nil
      end
    end
    context "when notifier does not implement init" do
      context "when notifier implements failed" do
        context "when notifier implements resolved" do
          it "raises Ragios::NotifierInitNotImplemented error" do
            options = {via: "no_init"}
            generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
            expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierInitNotImplemented)
            expect(generic_monitor.notifiers).to be_nil
          end
        end
      end
    end
    context "when notifier does not implement failed" do
      context "when notifier implements init" do
        context "when notifier implements resolved" do
          it "raises Ragios::NotifierFailedNotImplemented error" do
            options = {via: "no_failed"}
            generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
            expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierFailedNotImplemented)
            expect(generic_monitor.notifiers).to be_nil
          end
        end
      end
    end
    context "when notifier does not implement resolved" do
      context "when notifier implements init" do
        context "when notifier implements failed" do
          it "raises Ragios::NotifierResolvedNotImplemented error, no notifier is created" do
            options = {via: "no_resolved"}
            generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
            expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierResolvedNotImplemented)
            expect(generic_monitor.notifiers).to be_nil
          end
        end
      end
    end
    context "when notifier implements init" do
      context "when notifier implements failed" do
        context "when notifier implements resolved" do
          context "when a single notifier is included in options" do
            it "creates a single notifier" do
              options = {via: "good_notifier"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect(generic_monitor.create_notifiers.count).to eq(1)
              expect(generic_monitor.create_notifiers).to include(a_kind_of(Ragios::Notifiers::GoodNotifier))
              expect(generic_monitor.notifiers).to include(a_kind_of(Ragios::Notifiers::GoodNotifier))
            end
          end
          context "when multiple notifiers are included in options" do
            context "when all provided notifiers are valid" do
              it "creates multiple notifers" do
                options = {via: ["good_notifier", "other_good_notifier"]}
                generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
                expect(generic_monitor.create_notifiers.count).to eq(2)
                expect(generic_monitor.create_notifiers).to include(a_kind_of(Ragios::Notifiers::GoodNotifier))
                expect(generic_monitor.notifiers).to include(a_kind_of(Ragios::Notifiers::OtherGoodNotifier))
              end
            end
            context "when one of the provided notifiers are invalid" do
              it "raises an exception, does not create any notifier" do
                options = {via: ["good_notifier", "other_good_notifier", "no_resolved"]}
                generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
                expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierResolvedNotImplemented)
                expect(generic_monitor.notifiers).to be_nil
              end
            end
          end
        end
      end
    end
  end
end
