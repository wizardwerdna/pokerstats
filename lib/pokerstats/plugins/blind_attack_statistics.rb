class BlindAttackStatistics < HandStatistics::Plugin
  def initialize handstatistics
    super(handstatistics)
    @blind_attack_state = :no_action_taken
    @blind_attack_opportunity = {}
    @blind_attack_opportunity_taken ={}
    @blind_defense_opportunity = {}
    @blind_defense_opportunity_taken = {}
  end
  
  def blind_attack_opportunity?(screen_name)
    @blind_attack_opportunity[screen_name]
  end
  
  def blind_attack_opportunity_taken?(screen_name)
    @blind_attack_opportunity_taken[screen_name]
  end
  
  def blind_defense_opportunity?(screen_name)
    @blind_defense_opportunity[screen_name]
  end
  
  def blind_defense_opportunity_taken?(screen_name)
    @blind_defense_opportunity_taken[screen_name]
  end
  
  def self.report_specification
    [
      # [key,                               sql_type,   function]
      [:is_blind_attack_opportunity,        'INTEGER',  :blind_attack_opportunity?],
      [:is_blind_attack_opportunity_taken,  'INTEGER',  :blind_attack_opportunity_taken?],
      [:is_blind_defense_opportunity,       'INTEGER',  :blind_defense_opportunity?],
      [:is_blind_defense_opportunity_taken, 'INTEGER',  :blind_defense_opportunity_taken?]
    ]
  end
  
  # def report(screen_name)
  #   {
  #     :is_blind_attack_opportunity => blind_attack_opportunity?(screen_name),
  #     :is_blind_attack_opportunity_taken => blind_attack_opportunity_taken?(screen_name),
  #     :is_blind_defense_opportunity => blind_defense_opportunity?(screen_name),
  #     :is_blind_defense_opportunity_taken => blind_defense_opportunity_taken?(screen_name)
  #   }
  # end
      
  def apply_action action, street
    player = action[:screen_name]
    aggression = action[:aggression]

    return if aggression == :neutral || street != :preflop

    @blind_defense_opportunity[player] ||= @hand_statistics.blind?(player) && @blind_attack_state == :attacker_raised_first_in
    @blind_defense_opportunity_taken[player] ||= @blind_defense_opportunity[player] && aggression != :fold
    case @blind_attack_state
    when :no_action_taken
      @blind_attack_opportunity[player] ||= @hand_statistics.attacker?(player)
      @blind_attack_opportunity_taken[player] ||= @hand_statistics.attacker?(player) && aggression == :aggressive
      @blind_attack_state = case aggression
      when :aggressive
        @hand_statistics.attacker?(player) ? :attacker_raised_first_in : :responsive_action_taken
      when :passive
        :responsive_action_taken
      else
        :no_action_taken
      end
    when :attacker_raised_first_in
      @blind_attack_opportunity[player] ||= false
      @blind_attack_opportunity_taken[player] ||= false
      @blind_attack_state = :responsive_action_taken unless [:check, :fold].member?(aggression)
    when :responsive_action_taken
      @blind_attack_opportunity[player] ||= false
      @blind_attack_opportunity_taken[player] ||= false      
    else raise "invalid state: #{@blind_attack_state}"
    end
  end
end