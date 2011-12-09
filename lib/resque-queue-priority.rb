require 'resque'
require 'resque/worker'
require 'resque/plugins/queue_priority/version'
require 'resque/plugins/queue_priority/attributes'
require 'resque/plugins/queue_priority/priority'

Resque.send(:extend, Resque::Plugins::QueuePriority::Attributes)
Resque::Worker.send(:include, Resque::Plugins::QueuePriority::Priority)
