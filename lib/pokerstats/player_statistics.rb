module Pokerstats
  class PlayerStatistics

    def initialize
      @aggregate_statistics = {}
    end

    def reports
      @aggregate_statistics
    end
  
    def aggregate_numeric_statistic each_player, reports, aggregate_stat, hand_stat
      @aggregate_statistics[each_player][aggregate_stat] ||= 0
      @aggregate_statistics[each_player][aggregate_stat] += reports[each_player][hand_stat]
    end
  
    def aggregate_boolean_statistic each_player, reports, aggregate_stat, hand_stat
      @aggregate_statistics[each_player][aggregate_stat] ||= 0
      @aggregate_statistics[each_player][aggregate_stat] += 1 if reports[each_player][hand_stat]
    end
    
    def aggregate_three_part_statistic each_player, reports, aggregate_stat, hand_stat
        # puts "a3ps(#{each_player},reports,#{aggregate_stat.inspect},#{hand_stat.inspect}) where reports[][]=#{reports[each_player][hand_stat].inspect}" if each_player == "wizardwerdna"
        raise "diddledoo#{hand_stat}" + reports[each_player].to_yaml unless reports[each_player].keys.include?(hand_stat)
        t_stat_opportunity = ((aggregate_stat.to_s) + "_opportunity").to_sym
        t_stat_opportunity_taken = ((aggregate_stat.to_s) + "_opportunity_taken").to_sym
        @aggregate_statistics[each_player][t_stat_opportunity] ||=0
        @aggregate_statistics[each_player][t_stat_opportunity_taken] ||=0
        @aggregate_statistics[each_player][t_stat_opportunity] += 1 unless reports[each_player][hand_stat].nil?
        @aggregate_statistics[each_player][t_stat_opportunity_taken] += 1 if reports[each_player][hand_stat]
    end
  
    def aggregate_statistic each_player, reports, aggregate_stat, hand_stat
      @aggregate_statistics[each_player][aggregate_stat] ||= 0
      if /^is_/ =~ hand_stat.to_s
        @aggregate_statistics[each_player][aggregate_stat] += 1 if reports[each_player][hand_stat]
      else
        @aggregate_statistics[each_player][aggregate_stat] += reports[each_player][hand_stat]
      end
    end
  
    def record hand_statistics
      reports = hand_statistics.reports
# puts reports.to_yaml
      reports.keys.each do |each_player|
        raise "cbet_flop for #{each_player} inconsistent" if reports[:call_cbet_flop].nil? ^ reports[:fold_to_cbet_flop].nil?
        raise "preflop_3bet for #{each_player} inconsistent" if reports[:call_preflop_3bet].nil? ^ reports[:fold_to_preflop_3bet].nil?
        @aggregate_statistics[each_player] ||= {}
      
        @aggregate_statistics[each_player][:t_hands] ||= 0
        @aggregate_statistics[each_player][:t_hands] += 1
        @aggregate_statistics[each_player][:t_vpip] ||= 0
        @aggregate_statistics[each_player][:t_vpip] += 1 unless reports[each_player][:paid].zero?
        aggregate_numeric_statistic each_player, reports, :t_posted, :posted
        aggregate_numeric_statistic each_player, reports, :t_paid, :paid
        aggregate_numeric_statistic each_player, reports, :t_won, :won
        aggregate_numeric_statistic each_player, reports, :t_preflop_passive, :preflop_passive
        aggregate_numeric_statistic each_player, reports, :t_preflop_aggressive, :preflop_aggressive
        aggregate_numeric_statistic each_player, reports, :t_postflop_passive, :postflop_passive
        aggregate_numeric_statistic each_player, reports, :t_postflop_aggressive, :postflop_aggressive
        aggregate_boolean_statistic each_player, reports, :t_blind_attack_opportunity, :is_blind_attack_opportunity
        aggregate_boolean_statistic each_player, reports, :t_blind_attack_opportunity_taken, :is_blind_attack_opportunity_taken
        aggregate_boolean_statistic each_player, reports, :t_blind_defense_opportunity, :is_blind_defense_opportunity
        aggregate_boolean_statistic each_player, reports, :t_blind_defense_opportunity_taken, :is_blind_defense_opportunity_taken
        aggregate_boolean_statistic each_player, reports, :t_pfr_opportunity, :is_pfr_opportunity
        aggregate_boolean_statistic each_player, reports, :t_pfr_opportunity_taken, :is_pfr_opportunity_taken
        aggregate_boolean_statistic each_player, reports, :t_f_cbet, :f_cbet
        aggregate_boolean_statistic each_player, reports, :t_f_cbet_o, :f_cbet_o
        aggregate_boolean_statistic each_player, reports, :t_c_f_cbet, :c_f_cbet
        aggregate_boolean_statistic each_player, reports, :t_c_f_cbet_o, :c_f_cbet_o
        aggregate_boolean_statistic each_player, reports, :t_f2_f_cbet, :f2_f_cbet
        aggregate_boolean_statistic each_player, reports, :t_f2_f_cbet_o, :f2_f_cbet_o
        aggregate_boolean_statistic each_player, reports, :t_p_3bet, :p_3bet
        aggregate_boolean_statistic each_player, reports, :t_p_3bet_o, :p_3bet_o
        aggregate_boolean_statistic each_player, reports, :t_c_p_3bet, :c_p_3bet
        aggregate_boolean_statistic each_player, reports, :t_f2_p_3bet, :f2_p_3bet
        aggregate_boolean_statistic each_player, reports, :t_p_4bet_o, :p_4bet_o
      end
    end
  end
end