#!/usr/bin/env ruby
require 'logger'

$LOAD_PATH.unshift ::File.expand_path(::File.dirname(__FILE__) + '/lib')
require 'resque/server'
require 'resque-queue-priority-server'

use Rack::ShowExceptions
run Resque::Server.new
