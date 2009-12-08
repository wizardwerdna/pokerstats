module Pokerstats
    class StreetBetStatistics < HandStatistics::Plugin
        def self.report_specification
            [
                [:p_2bet,	"boolean",	:p_2bet?],
                [:p_2bet_o,	"boolean",	:p_2bet_o?],
                [:p_3bet,	"boolean",	:p_3bet?],
                [:p_3bet_o,	"boolean",	:p_3bet_o?],
                [:p_4bet,	"boolean",	:p_4bet?],
                [:p_4bet_o,	"boolean",	:p_4bet_o?],
                [:p_5bet_o,	"boolean",	:p_5bet_o?],
                [:f_1bet,	"boolean",	:f_1bet?],
                [:f_1bet_o,	"boolean",	:f_1bet_o?],
                [:f_2bet,	"boolean",	:f_2bet?],
                [:f_2bet_o,	"boolean",	:f_2bet_o?],
                [:f_3bet,	"boolean",	:f_3bet?],
                [:f_3bet_o,	"boolean",	:f_3bet_o?],
                [:f_4bet,	"boolean",	:f_4bet?],
                [:f_4bet_o,	"boolean",	:f_4bet_o?],
                [:f_5bet_o,	"boolean",	:f_5bet_o?],
                [:t_1bet,	"boolean",	:t_1bet?],
                [:t_1bet_o,	"boolean",	:t_1bet_o?],
                [:t_2bet,	"boolean",	:t_2bet?],
                [:t_2bet_o,	"boolean",	:t_2bet_o?],
                [:t_3bet,	"boolean",	:t_3bet?],
                [:t_3bet_o,	"boolean",	:t_3bet_o?],
                [:t_4bet,	"boolean",	:t_4bet?],
                [:t_4bet_o,	"boolean",	:t_4bet_o?],
                [:t_5bet_o,	"boolean",	:t_5bet_o?],
                [:r_1bet,	"boolean",	:r_1bet?],
                [:r_1bet_o,	"boolean",	:r_1bet_o?],
                [:r_2bet,	"boolean",	:r_2bet?],
                [:r_2bet_o,	"boolean",	:r_2bet_o?],
                [:r_3bet,	"boolean",	:r_3bet?],
                [:r_3bet_o,	"boolean",	:r_3bet_o?],
                [:r_4bet,	"boolean",	:r_4bet?],
                [:r_4bet_o,	"boolean",	:r_4bet_o?],
                [:r_5bet_o,	"boolean",	:r_5bet_o?],

                [:f2_p_1bet,	"boolean",	:f2_p_1bet?],
                [:f2_p_2bet,	"boolean",	:f2_p_2bet?],
                [:f2_p_3bet,	"boolean",	:f2_p_3bet?],
                [:f2_p_4bet,	"boolean",	:f2_p_4bet?],
                [:f2_f_1bet,	"boolean",	:f2_f_1bet?],
                [:f2_f_2bet,	"boolean",	:f2_f_2bet?],
                [:f2_f_3bet,	"boolean",	:f2_f_3bet?],
                [:f2_f_4bet,	"boolean",	:f2_f_4bet?],
                [:f2_t_1bet,	"boolean",	:f2_t_1bet?],
                [:f2_t_2bet,	"boolean",	:f2_t_2bet?],
                [:f2_t_3bet,	"boolean",	:f2_t_3bet?],
                [:f2_t_4bet,	"boolean",	:f2_t_4bet?],
                [:f2_r_1bet,	"boolean",	:f2_r_1bet?],
                [:f2_r_2bet,	"boolean",	:f2_r_2bet?],
                [:f2_r_3bet,	"boolean",	:f2_r_3bet?],
                [:f2_r_4bet,	"boolean",	:f2_r_4bet?],

                [:c_p_1bet,	"boolean",	:c_p_1bet?],
                [:c_p_2bet,	"boolean",	:c_p_2bet?],
                [:c_p_3bet,	"boolean",	:c_p_3bet?],
                [:c_p_4bet,	"boolean",	:c_p_4bet?],
                [:c_f_1bet,	"boolean",	:c_f_1bet?],
                [:c_f_2bet,	"boolean",	:c_f_2bet?],
                [:c_f_3bet,	"boolean",	:c_f_3bet?],
                [:c_f_4bet,	"boolean",	:c_f_4bet?],
                [:c_t_1bet,	"boolean",	:c_t_1bet?],
                [:c_t_2bet,	"boolean",	:c_t_2bet?],
                [:c_t_3bet,	"boolean",	:c_t_3bet?],
                [:c_t_4bet,	"boolean",	:c_t_4bet?],
                [:c_r_1bet,	"boolean",	:c_r_1bet?],
                [:c_r_2bet,	"boolean",	:c_r_2bet?],
                [:c_r_3bet,	"boolean",	:c_r_3bet?],
                [:c_r_4bet,	"boolean",	:c_r_4bet?],

                [:last_aggr_preflop,	'boolean',	:last_aggr_preflop],
                [:last_aggr_flop,	'boolean',	:last_aggr_flop],
                [:last_aggr_turn,	'boolean',	:last_aggr_turn],
                [:last_aggr_river,	'boolean',	:last_aggr_river],

                [:f_cbet,	'boolean',	:f_cbet?],
                [:f_cbet_o,	"boolean",	:f_cbet_o?],
                [:t_cbet,	'boolean',	:t_cbet?],
                [:t_cbet_o,	"boolean",	:t_cbet_o?],
                [:r_cbet,	'boolean',	:r_cbet?],
                [:r_cbet_o,	"boolean",	:r_cbet_o?],
                [:c_f_cbet,	'boolean',	:c_f_cbet?],
                [:c_f_cbet_o,	"boolean",	:c_f_cbet_o?],
                [:c_t_cbet,	'boolean',	:c_t_cbet?],
                [:c_t_cbet_o,	"boolean",	:c_t_cbet_o?],
                [:c_r_cbet,	'boolean',	:c_r_cbet?],
                [:c_r_cbet_o,	"boolean",	:c_r_cbet_o?],
                [:f2_f_cbet,	'boolean',	:f2_f_cbet?],
                [:f2_f_cbet_o,	"boolean",	:f2_f_cbet_o?],
                [:f2_t_cbet,	'boolean',	:f2_t_cbet?],
                [:f2_t_cbet_o,	"boolean",	:f2_t_cbet_o?],
                [:f2_r_cbet,	'boolean',	:f2_r_cbet?],
                [:f2_r_cbet_o,	"boolean",	:f2_r_cbet_o?],

                [:f_dbet,	'boolean',	:f_dbet?],
                [:f_dbet_o,	"boolean",	:f_dbet_o?],
                [:t_dbet,	'boolean',	:t_dbet?],
                [:t_dbet_o,	"boolean",	:t_dbet_o?],
                [:r_dbet,	'boolean',	:r_dbet?],
                [:r_dbet_o,	"boolean",	:r_dbet_o?],
                [:c_f_dbet,	'boolean',	:c_f_dbet?],
                [:c_f_dbet_o,	"boolean",	:c_f_dbet_o?],
                [:c_t_dbet,	'boolean',	:c_t_dbet?],
                [:c_t_dbet_o,	"boolean",	:c_t_dbet_o?],
                [:c_r_dbet,	'boolean',	:c_r_dbet?],
                [:c_r_dbet_o,	"boolean",	:c_r_dbet_o?],
                [:f2_f_dbet,	'boolean',	:f2_f_dbet?],
                [:f2_f_dbet_o,	"boolean",	:f2_f_dbet_o?],
                [:f2_t_dbet,	'boolean',	:f2_t_dbet?],
                [:f2_t_dbet_o,	"boolean",	:f2_t_dbet_o?],
                [:f2_r_dbet,	'boolean',	:f2_r_dbet?],
                [:f2_r_dbet_o,	'boolean',	:f2_r_dbet_o?]
            ]
        end
        
        attr_accessor :street_bets, :fold_to_street_bets, :last_aggr_player
                
        for street in [:preflop, :flop, :turn, :river]
            
            street_first = case street
                when :preflop then :p
                when :flop then :f
                when :turn then :t
                when :river then :r
            end
            
            #
            # last agresssion functions
            #   true only if player made the last aggressive move on the street
            #   nil otherwise
            #   never false
            #
            class_eval <<-LAST_AGGR_FUNCTIONS
            def last_aggr_#{street} player
                @last_aggr_player[:#{street}] && (player==@last_aggr_player[:#{street}] ? true : nil)
            end
            LAST_AGGR_FUNCTIONS

            #
            # make_, c_, and f2_ functions, by bet and street street
            #
            for bet in 1..5
                class_eval <<-STREET_AND_BET_FUNCTIONS
                def #{street_first}_#{bet}bet(player)
                    @street_bets[#{street.inspect}] && @street_bets[#{street.inspect}][#{bet}][player] 
                end
                def #{street_first}_#{bet}bet?(player)
                    #{street_first}_#{bet}bet(player) || false
                end
                def #{street_first}_#{bet}bet_o?(player)
                    !#{street_first}_#{bet}bet(player).nil?
                end
                STREET_AND_BET_FUNCTIONS
            end
            
            for bet in 1..4
                class_eval <<-RESPOND_TO_STREET_AND_BET_FUNCTIONS
                def c_#{street_first}_#{bet}bet(player)
                    @call_street_bets[#{street.inspect}] && @call_street_bets[#{street.inspect}][#{bet}][player]
                end
                def c_#{street_first}_#{bet}bet?(player)
                    c_#{street_first}_#{bet}bet(player) || false
                end
                # def c_#{street_first}_#{bet}bet_o?(player)
                #     !c_#{street_first}_#{bet}bet(player).nil?
                # end
                def f2_#{street_first}_#{bet}bet(player)
                    @fold_to_street_bets[#{street.inspect}] && @fold_to_street_bets[#{street.inspect}][#{bet}][player]
                end
                def f2_#{street_first}_#{bet}bet?(player)
                    f2_#{street_first}_#{bet}bet(player) || false
                end
                # def f2_#{street_first}_#{bet}bet_o?(player)
                #     !f2_#{street_first}_#{bet}bet(player).nil?
                # end
                RESPOND_TO_STREET_AND_BET_FUNCTIONS
            end
        end
        
        for street in [:flop, :turn, :river]
            last_street = case street
                when :flop then :preflop
                when :turn then :flop
                when :river then :turn
            end
            
            street_first = case street
                when :preflop then :p
                when :flop then :f
                when :turn then :t
                when :river then :r
            end
            
            #
            # make, c_ and f2_ cbet and dbet functions, by street
            #
            # cbets (continuation bets) are first-in bets after making last agression on the previous street
            #
            # dbets (donk bets) are first-in bets, made after calling another player's aggression out of position on the previous street
            #

            class_eval <<-FTR_FUNCTIONS
            def #{street_first}_cbet(player)
                last_aggr_#{last_street}(player) && #{street_first}_1bet(player)
            end
            def #{street_first}_cbet?(player)
                #{street_first}_cbet(player) || false
            end
            def #{street_first}_cbet_o?(player)
                !#{street_first}_cbet(player).nil?
            end
            def f2_#{street_first}_cbet(player)
                @first_aggr_player[:#{street}] && #{street_first}_cbet(@first_aggr_player[:#{street}]) && f2_#{street_first}_1bet(player)
            end
            def f2_#{street_first}_cbet?(player)
                f2_#{street_first}_cbet(player) || false
            end
            def f2_#{street_first}_cbet_o?(player)
                !f2_#{street_first}_cbet(player).nil?
            end
            def c_#{street_first}_cbet(player)
                @first_aggr_player[:#{street}] && #{street_first}_cbet(@first_aggr_player[:#{street}]) && c_#{street_first}_1bet(player)
            end
            def c_#{street_first}_cbet?(player)
                c_#{street_first}_cbet(player) || false
            end
            def c_#{street_first}_cbet_o?(player)
                !c_#{street_first}_cbet(player).nil?
            end
            def #{street_first}_dbet(player)
                return nil unless @last_aggr_player[:#{last_street}] && @hand_statistics.betting_order?(player, @last_aggr_player[:#{last_street}])
                #{street_first}_1bet(player)
            end
            def #{street_first}_dbet?(player)
                #{street_first}_dbet(player) || false
            end
            def #{street_first}_dbet_o?(player)
                !#{street_first}_dbet(player).nil?
            end
            def f2_#{street_first}_dbet(player)
                return nil unless @first_aggr_player[:#{street}] && #{street_first}_dbet(@first_aggr_player[:#{street}])
                f2_#{street_first}_1bet(player)
            end
            def f2_#{street_first}_dbet?(player)
                f2_#{street_first}_dbet(player) || false
            end
            def f2_#{street_first}_dbet_o?(player)
                !f2_#{street_first}_dbet(player).nil?
            end
            def c_#{street_first}_dbet(player)
                return nil unless @first_aggr_player[:#{street}] && #{street_first}_dbet(@first_aggr_player[:#{street}])
                c_#{street_first}_1bet(player)
            end
            def c_#{street_first}_dbet?(player)
                c_#{street_first}_dbet(player) || false
            end
            def c_#{street_first}_dbet_o?(player)
                !c_#{street_first}_dbet(player).nil?
            end
            FTR_FUNCTIONS
        end

        def initialize handstatistics
            @street_bets = {}
            @call_street_bets = {}
            @fold_to_street_bets = {}
            @first_aggr_player = {}
            @last_aggr_player = {}
            [:preflop, :flop, :turn, :river].each do|each|
                @street_bets[each] = [{}, {}, {}, {}, {}, {}] 
                @call_street_bets[each] = [{}, {}, {}, {}, {}]
                @fold_to_street_bets[each] = [{}, {}, {}, {}, {}]
            end
            super handstatistics
        end

        def register_player screen_name, street, player
        end

        def street_transition street
            case street
            when :preflop
                @last_bet = 1
            when :flop, :turn, :river
                @last_bet = 0
            else
                @last_bet = nil
            end
        end

        def street_transition_for_player street, player
        end

        def apply_action action, street
            unless @last_bet.nil?
                # puts "apply_action(#{action[:aggression]}, #{street}) with @last_bet == #{@last_bet}"
                if @last_bet.between?(0,4)
                    @fold_to_street_bets[street][@last_bet][action[:screen_name]] = action[:description] == "folds"
                    @call_street_bets[street][@last_bet][action[:screen_name]] = action[:description] == "calls"
                end
                if @last_bet.between?(0,4)
                    @street_bets[street][@last_bet+1][action[:screen_name]] = action[:aggression] == :aggressive
                end
                if action[:aggression] == :aggressive
                    @last_bet+=1
                    @first_aggr_player[street] ||= action[:screen_name]
                    @last_aggr_player[street] = action[:screen_name]
                end
            end
        end
    end
end