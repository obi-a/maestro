# Maestro

[![Build Status](https://travis-ci.org/obi-a/maestro.svg?branch=master)](https://travis-ci.org/obi-a/maestro)

* Easy web browser automation
* Monitor website functionality and uptime with a real web browser
* Receive a screenshot when functionality does not work as expected
* Receive a screenshot when web page elements are not displaying in the browser

## What is Maestro
Maestro = [Ragios](https://github.com/obi-a/ragios) + [Uptime_monitor plugin](https://github.com/obi-a/uptime_monitor) + [Firefox](https://en.wikipedia.org/wiki/Firefox)/[Chrome](https://en.wikipedia.org/wiki/Chrome) + [Selenium Grid](http://www.seleniumhq.org/docs/07_selenium_grid.jsp) + [Docker Compose](https://docs.docker.com/compose/)

With Maestro, all the above is setup and configured running in Docker containers for very easy Website functionality and uptime monitoring with a real web browser (Chrome or Firefox).

## Usage:

Clone the Maestro Repo:
```
git clone git@github.com:obi-a/maestro.git
```
Switch to the directory of the cloned repo
```
cd maestro
```
Start Ragios with Docker-compose
```
docker-compose up -d
```
Open the Web UI to confirm Ragios is running fine. In your browser open http://localhost:5041

Maestro runs Ragios with the Uptime_monitor plugin and its dependencies already installed and configured.

## Using the Uptime Monitor
The easiest way to start adding monitors is using the Ragios ruby client with pry console. You can use PRY from Ragios Web Service container.
To access the web service container
```
docker-compose exec web pry
```
This approach is only for testing Ragios, ideally the ragios client should run in a different host or node from the rest of the stack.

Using ragios-client to add a monitor inside pry.
```ruby
require "ragios-client"
ragios = Ragios::Client.new

monitor = {
  monitor: "Google.com home page",
  url: "https://google.com",
  every: "5m",
  via: "log_notifier",
  plugin: "uptime_monitor",
  exists?: 'title.with_text("Google")',
  browser: "firefox"
}
ragios.create(monitor)
# => {:monitor=>"Google.com home page",
# :url=>"https://google.com",
# :every=>"5m",
# :via=>["log_notifier"],
# :plugin=>"uptime_monitor",
# :exists?=>"title.with_text(\"Google\")",
# :browser=>"firefox",
# :created_at_=>"2018-02-10 15:17:13 UTC",
# :status_=>"active",
# :type=>"monitor",
# :_id=>"1181d969-b4f1-4ba6-9388-6f057f18cdb7"}
```
The monitor created above uses the uptime_monitor plugin to launch the firefox web browser every hour to visit Google.com and verify that the homepage html title tag contains the text string "Google". The validation is defined in the key/pair *exists?: 'title.with_text("Google")'*.

For a complete guide on using ragios-client see here: [Using Ragios](http://www.whisperservers.com/ragios/ragios-saint-ruby/using-ragios/)

For a complete guide on using the uptime_monitor plugin see here: [Using Uptime_monitor plugin](https://github.com/obi-a/uptime_monitor/blob/master/README.md#usage)

## Configure Ragios & Uptime Monitor
- See details on general Ragios configuration here [Ragios Configuration](http://www.whisperservers.com/ragios/configuration/)
- Ragios ships with Amazon SES email notifier built-in see details on Ragios Notifications here: [Ragios Notifications](http://www.whisperservers.com/ragios/ragios-saint-ruby/notifications/)
- To configure uptime monitor to send screenshots when it detects a problem, add the correct environment variables to docker compose, the env vars are described here: [Uptime Monitor enable Screenshots] (https://github.com/obi-a/uptime_monitor#screenshots)

## License:
MIT License.

Copyright (c) 2018 Obi Akubue, obi-akubue.org
