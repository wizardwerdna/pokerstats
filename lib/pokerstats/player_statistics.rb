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
      reports.keys.each do |each_player|
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
        aggregate_boolean_statistic each_player, reports, :t_cbet_opportunity, :is_cbet_opportunity
        aggregate_boolean_statistic each_player, reports, :t_cbet_opportunity_taken, :is_cbet_opportunity_taken
      end
    end
  end
end