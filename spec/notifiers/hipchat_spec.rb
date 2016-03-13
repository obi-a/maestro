require 'spec_base.rb'
require 'notifier_test_setup.rb'

describe Ragios::Notifier::Hipchat do

  it "tests a monitor" do
    Ragios::NotifierTest::failed_resolved('Hipchat test','hipchat')
  end

  it "should send a notification message via hipchat" do
    hipchat  = Ragios::Notifier::Hipchat.new({monitor: "Awesome Monitor", room: "Southmunn"})
    hipchat.post({
      "color": "green",
      "message": "Test notification message from Ragios via twitter. " + "Created on: " + Time.now.to_s,
      "notify": false,
      "message_format": "text"
    })
  end
end
