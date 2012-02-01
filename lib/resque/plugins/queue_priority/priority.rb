require 'resque/worker'

module Resque
  module Plugins
    module QueuePriority

      module Priority

        def self.included(klass)
          klass.instance_eval do
            alias_method :queues_without_priority, :queues
            alias_method :queues, :queues_with_priority
          end
        end

        def queues_with_priority
          all_queues = queues_without_priority
          result = []
          default_idx = -1, default_fairly = false;

          # Walk the priority patterns, extract each into its own bucket
          buckets = Resque.priority_buckets
          buckets.each do |bucket|
            bucket_pattern = bucket['pattern']
            fairly = bucket['fairly']

            # note the position of the default bucket for inserting the remaining queues at that location
            if bucket_pattern == 'default'
              default_idx = result.size
              default_fairly = fairly
              next
            end

            bucket_queues, remaining = [], []
            
            patterns = bucket_pattern.split(',')
            patterns.each do |pattern|
              pattern = pattern.strip
              
              # string[0] in 1.8.7 is different than in 1.9 so use .chars.first 
              if pattern.chars.first == '!'
                negated = true
                pattern = pattern[1..-1]
              end
              
              patstr = pattern.gsub(/\*/, ".*")
              pattern = /^#{patstr}$/
            
            
              if negated
                bucket_queues -= bucket_queues.grep(pattern)
              else
                bucket_queues.concat(all_queues.grep(pattern))
              end
            
            end
            
            bucket_queues.uniq!
            bucket_queues.shuffle! if fairly
            all_queues = all_queues - bucket_queues
            
            result << bucket_queues
            
          end

          # insert the remaining queues at the position the default item was at (or last)
          all_queues.shuffle! if default_fairly
          result.insert(default_idx, all_queues)
          result.flatten!

          return result
        end

      end

    end
  end
end
