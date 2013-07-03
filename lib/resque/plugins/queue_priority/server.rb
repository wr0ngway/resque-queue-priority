require 'resque-queue-priority'

module Resque
  module Plugins
    module QueuePriority

      module Server

        VIEW_PATH = File.join(File.dirname(__FILE__), 'server', 'views')

        def self.registered(app)

          app.get "/queuepriority" do
            @priorities = Resque.priority_buckets
            queuepriority_view :priorities
          end

          app.post "/queuepriority" do
            priorities = params['priorities']
            Resque.priority_buckets = priorities
            redirect to("/queuepriority")
          end

          app.helpers do
            def queuepriority_view(filename, options = {}, locals = {})
              erb(File.read(File.join(::Resque::Plugins::QueuePriority::Server::VIEW_PATH, "#{filename}.erb")), options, locals)
            end
          end

          app.tabs << "QueuePriority"
        end

      end

    end
  end
end
