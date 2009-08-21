class AggressionStatistics < HandStatistics::Plugin
  
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
  
  def self.report_specification
    [
      # [key,                               sql_type,   function]
      [:preflop_passive,      'INTEGER',  :preflop_passive],
      [:postflop_passive,     'INTEGER',  :postflop_passive],
      [:preflop_aggressive,   'INTEGER',  :preflop_aggressive],
      [:postflop_aggressive,  'INTEGER',  :postflop_aggressive]
    ]
  end
  
  # def report screen_name
  #   {
  #     :preflop_passive => preflop_passive(screen_name),
  #     :postflop_passive => postflop_passive(screen_name),
  #     :preflop_aggressive => preflop_aggressive(screen_name),
  #     :postflop_aggressive => postflop_aggressive(screen_name)
  #   }
  # end
  # 
  # def migration_segment
  #   return <<-FOO
  #   FOO
  # end

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