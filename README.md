A resque plugin for specifying the order a worker will prioritize queues in.

Authored against Resque 1.17.1, so it at least works with that - try running the tests if you use a different version of resque

Usage:

Start your workers with a QUEUE that contains many queue names - most useful when using '\*' or a plugin like resque-dynamic-queues

Then you should set use the web ui to determine the order a worker will pick a queue for processing.  The "Fairly" checkbox makes all queues that match that pattern get ordered in a random fashion (i.e. provides the same functionality as resque-fairly).

The queue priority web ui is shown as a tab in the resque-web UI, and allows you to define the queue priorities.  To activate it, you need to require 'resque-queue-priority-server' in whatever initializer you use to bring up resque-web.


Contributors:

Matt Conway ( https://github.com/wr0ngway )
