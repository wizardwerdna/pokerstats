module Pokerstats
  class AggressionStatistics < HandStatistics::Plugin

    def self.report_specification
      [
        # [key,                               sql_type,   function]
        [:preflop_passive,      'integer',  :preflop_passive],
        [:postflop_passive,     'integer',  :postflop_passive],
        [:preflop_aggressive,   'integer',  :preflop_aggressive],
        [:postflop_aggressive,  'integer',  :postflop_aggressive]
      ]
    end

    def initialize handstatistics
      super handstatistics
      @preflop_passive = {}
      @preflop_aggressive = {}
      @postflop_passive = {}
      @postflop_aggressive = {}
    end
    
    def preflop_passive(screen_name)
      @preflop_passive[screen_name]
    end
  
    def postflop_passive(screen_name)
      @postflop_passive[screen_name]
    end
  
    def preflop_aggressive(screen_name)
      @preflop_aggressive[screen_name]
    end
  
    def postflop_aggressive(screen_name)
      @postflop_aggressive[screen_name]
    end

    def register_player screen_name, street
      @preflop_passive[screen_name] = 0
      @preflop_aggressive[screen_name] = 0
      @postflop_passive[screen_name] = 0
      @postflop_aggressive[screen_name] = 0
    end

    def apply_action action, street
      aggression = action[:aggression]
      player = action[:screen_name]
      if [:prelude, :preflop].member?(street)
        @preflop_aggressive[player] +=1 if aggression == :aggressive
        @preflop_passive[player] += 1 if aggression == :passive
      else
        @postflop_aggressive[player] +=1 if aggression == :aggressive
        @postflop_passive[player] +=1 if aggression == :passive
      end
    end
  end
end