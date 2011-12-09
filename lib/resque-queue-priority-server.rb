require 'resque-queue-priority'
require 'resque/plugins/queue_priority/server'

Resque::Server.register Resque::Plugins::QueuePriority::Server
