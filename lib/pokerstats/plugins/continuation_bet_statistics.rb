module Pokerstats
  class ContinuationBetStatistics < HandStatistics::Plugin
    def initialize handstatistics
      super(handstatistics)
      @last_preflop_raiser = nil
      @number_preflop_raises = 0
      @first_aggressor = {}
      @first_aggression_opportunity = {}
      @first_aggression_opportunity_taken = {}
    end
  
    def cbet_opportunity?(screen_name, street = :flop)
      # puts "cbet_opportunity?(#{screen_name}, #{street})"
      # puts @first_aggression_opportunity.inspect
      @number_preflop_raises==1 && @last_preflop_raiser==screen_name && @first_aggression_opportunity[street] && @first_aggression_opportunity[street][screen_name]
    end
  
    def cbet_opportunity_taken?(screen_name, street = :flop)
      cbet_opportunity?(screen_name) && @first_aggression_opportunity_taken[street][screen_name]
    end
  
    def self.report_specification
      [
        # [key,                     sql_type,   function]
        [:is_cbet_opportunity,       'integer',  :cbet_opportunity?],
        [:is_cbet_opportunity_taken, 'integer',  :cbet_opportunity_taken?]
      ]
    end
  
    # 
    # def report(screen_name)
    #   {
    #     :is_cbet_opportunity => cbet_opportunity?(screen_name),
    #     :is_cbet_opportunity_taken => cbet_opportunity_taken?(screen_name)
    #   }
    # end
  
    def street_transition street
      @first_aggressor[street] = nil
      @first_aggression_opportunity[street] = {}
      @first_aggression_opportunity_taken[street] = {}
      super(street)
    end
  
    def street_transition_for_player street, player
      @first_aggression_opportunity[street][player] = nil
      @first_aggression_opportunity_taken[street][player] = false
    end
  
    def apply_action action, street
      player = action[:screen_name]
      aggression = action[:aggression]
      result = action[:result]
      if street == :preflop and result == :pay_to
        @number_preflop_raises += 1
        @last_preflop_raiser = player
      end
      if aggression != :neutral && @first_aggressor[street].nil? && @first_aggression_opportunity[street][player].nil?
        @first_aggression_opportunity[street][player] = true
        if aggression == :aggressive
          @first_aggressor[street] = player
          @first_aggression_opportunity_taken[street][player] = true
          @hand_statistics.players.each {|player| @first_aggression_opportunity[street][player] ||= false}
        end
      end
    end
  end
end