module Resque
  module Plugins
    module QueuePriority

      PRIORITY_KEY = "queue_priority"

      module Attributes

        def priority_buckets
          priorities = Array(redis.lrange(PRIORITY_KEY, 0, -1))
          priorities = priorities.collect {|p| Resque.decode(p) }
          priorities << {'pattern' => 'default'} unless priorities.find {|b| b['pattern'] == 'default' }
          return priorities
        end

        def priority_buckets=(data)
          redis.multi do
            redis.del(PRIORITY_KEY)
            Array(data).each do |v|
               redis.rpush(PRIORITY_KEY, Resque.encode(v))
            end
          end
        end

      end
    end
  end
end
