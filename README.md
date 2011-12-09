A resque plugin for specifying the order a worker will prioritize queues in.

Authored against Resque 1.17.1, so it at least works with that - try running the tests if you use a different version of resque

Usage:

Start your workers with a QUEUE that contains many queue names - this plugin is most useful when using '\*' or a plugin like resque-dynamic-queues.

The queue priority web ui is shown as a tab in the resque-web UI, and allows you to define the queue priorities.  To activate it, you need to require 'resque-queue-priority-server' in whatever initializer you use to bring up resque-web.

Then you should set use the web ui to determine the order a worker will pick a queue for processing.  The "Fairly" checkbox makes all queues that match that pattern get ordered in a random fashion (i.e. provides the same functionality as resque-fairly).

For example, say my resque system has the queues:

low_foo, low_bar, low_baz, high_foo, high_bar, high_baz, otherqueue, somequeue, myqueue

And I run my worker with QUEUE=\* (Note Resque wildcarding sorts queues)

If I set my patterns like:

high\_\* (fairly unchecked)  
default (fairly unchecked)  
low\_\* (fairly unchecked)  

Then, the worker will scan the queues for work in this order:
high_bar, high_baz, high_foo, myqueue, otherqueue, somequeue, low_bar, low_baz, low_foo

If I set my patterns like:

high\_\* (fairly checked)  
default (fairly checked)  
low\_\* (fairly checked)  

Then, the worker will scan the queues for work in this order:

\*[high_bar, high_baz, high_foo].shuffle, \*[myqueue, otherqueue, somequeue].shuffle, \*[low_bar, low_baz, low_foo].shuffle


Contributors:

Matt Conway ( https://github.com/wr0ngway )
