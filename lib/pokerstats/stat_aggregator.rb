module Pokerstats
  StatAggregationCount = Struct.new(:items, :total)
  class StatAggregator
    def initialize(specification = {})
      @specification = specification
      @data = {}
      @specification.keys.each do |key|
        @data[key] = StatAggregationCount.new(0, 0)
      end
    end
    
    def data
      @data
    end
    
    def apply hash
      @specification.each do |key, value|
        puts "applying specification #{key.inspect} with value specification #{value.inspect}"
        # determine datum value from specification
        datum = case value
        when Symbol
          hash[value]
        when Proc
          value.call(hash)
        else
          raise RuntimeError, "there is no valid specification for datum #{key.inspect}"
        end
        
        puts "... resulting in datum #{datum.inspect}"
        # apply datum value to aggregated data
        unless datum.nil?
          @data[key].items+=1
          if datum.kind_of? Numeric
            @data[key].total+=datum
          else
            @data[key].total+=1 if datum
          end
        end
      end
    end
  end
end