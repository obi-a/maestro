#!/usr/bin/env ruby
require 'daemons'
require 'securerandom'

ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))

options = {
  multiple: true,
  log_output: true,
  dir_mode: :normal,
  dir: 'tmp/pids',
  keep_pid_files: false,
  ontop: true
}

Daemons.run_proc("workers",  options) do

  require "#{ragios_dir}/lib/ragios"

  Ragios::Logging.setup(program_name: "Workers Service")

  Ragios::Logging.logger.info("starting out")

  receiver = Ragios::Monitors::Workers::Receiver.new
  trap("INT") { puts "Shutting down."; exit}

  receiver.run
end
