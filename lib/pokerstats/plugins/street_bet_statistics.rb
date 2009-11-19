module Pokerstats
    class StreetBetStatistics < HandStatistics::Plugin
        def self.report_specification
            [
                [:preflop_2bet,         "boolean",  :preflop_2bet],
                [:preflop_3bet,         "boolean",  :preflop_3bet],
                [:preflop_4bet,         "boolean",  :preflop_4bet],
                [:flop_1bet,            "boolean",  :flop_1bet],
                [:flop_2bet,            "boolean",  :flop_2bet],
                [:flop_3bet,            "boolean",  :flop_3bet],
                [:flop_4bet,            "boolean",  :flop_4bet],
                [:turn_1bet,            "boolean",  :turn_1bet],
                [:turn_2bet,            "boolean",  :turn_2bet],
                [:turn_3bet,            "boolean",  :turn_3bet],
                [:turn_4bet,            "boolean",  :turn_4bet],
                [:river_1bet,           "boolean",  :river_1bet],
                [:river_2bet,           "boolean",  :river_2bet],
                [:river_3bet,           "boolean",  :river_3bet],
                [:river_4bet,           "boolean",  :river_4bet],

                [:fold_to_preflop_1bet, "boolean",  :fold_to_preflop_1bet],
                [:fold_to_preflop_2bet, "boolean",  :fold_to_preflop_2bet],
                [:fold_to_preflop_3bet, "boolean",  :fold_to_preflop_3bet],
                [:fold_to_preflop_4bet, "boolean",  :fold_to_preflop_4bet],
                [:fold_to_flop_1bet,    "boolean",  :fold_to_flop_1bet],
                [:fold_to_flop_2bet,    "boolean",  :fold_to_flop_2bet],
                [:fold_to_flop_3bet,    "boolean",  :fold_to_flop_3bet],
                [:fold_to_flop_4bet,    "boolean",  :fold_to_flop_4bet],
                [:fold_to_turn_1bet,    "boolean",  :fold_to_turn_1bet],
                [:fold_to_turn_2bet,    "boolean",  :fold_to_turn_2bet],
                [:fold_to_turn_3bet,    "boolean",  :fold_to_turn_3bet],
                [:fold_to_turn_4bet,    "boolean",  :fold_to_turn_4bet],
                [:fold_to_river_1bet,   "boolean",  :fold_to_river_1bet],
                [:fold_to_river_2bet,   "boolean",  :fold_to_river_2bet],
                [:fold_to_river_3bet,   "boolean",  :fold_to_river_3bet],
                [:fold_to_river_4bet,   "boolean",  :fold_to_river_4bet],

                [:call_preflop_1bet,    "boolean",  :call_preflop_1bet],
                [:call_preflop_2bet,    "boolean",  :call_preflop_2bet],
                [:call_preflop_3bet,    "boolean",  :call_preflop_3bet],
                [:call_preflop_4bet,    "boolean",  :call_preflop_4bet],
                [:call_flop_1bet,       "boolean",  :call_flop_1bet],
                [:call_flop_2bet,       "boolean",  :call_flop_2bet],
                [:call_flop_3bet,       "boolean",  :call_flop_3bet],
                [:call_flop_4bet,       "boolean",  :call_flop_4bet],
                [:call_turn_1bet,       "boolean",  :call_turn_1bet],
                [:call_turn_2bet,       "boolean",  :call_turn_2bet],
                [:call_turn_3bet,       "boolean",  :call_turn_3bet],
                [:call_turn_4bet,       "boolean",  :call_turn_4bet],
                [:call_river_1bet,      "boolean",  :call_river_1bet],
                [:call_river_2bet,      "boolean",  :call_river_2bet],
                [:call_river_3bet,      "boolean",  :call_river_3bet],
                [:call_river_4bet,      "boolean",  :call_river_4bet],
                
                [:last_aggr_preflop,	'boolean',	:last_aggr_preflop],
                [:last_aggr_flop,	    'boolean',	:last_aggr_flop],
                [:last_aggr_turn,	    'boolean',	:last_aggr_turn],
                [:last_aggr_river,	    'boolean',	:last_aggr_river],

                [:cbet_flop,	        'boolean',	:cbet_flop],
                [:cbet_turn,	        'boolean',	:cbet_turn],
                [:cbet_river,	        'boolean',	:cbet_river],
                [:fold_to_cbet_flop,	'boolean',	:fold_to_cbet_flop],
                [:fold_to_cbet_turn,	'boolean',	:fold_to_cbet_turn],
                [:fold_to_cbet_river,	'boolean',	:fold_to_cbet_river],

                [:dbet_flop,	        'boolean',	:dbet_flop],
                [:dbet_turn,	        'boolean',	:dbet_turn],
                [:dbet_river,	        'boolean',	:dbet_river],
                [:fold_to_dbet_flop,	'boolean',	:fold_to_dbet_flop],
                [:fold_to_dbet_turn,	'boolean',	:fold_to_dbet_turn],
                [:fold_to_dbet_river,	'boolean',	:fold_to_dbet_river]
            ]
        end
        
        attr_accessor :street_bets, :fold_to_street_bets, :last_aggr_player
        
        #
        # These functions return one of three, not two values, and hence do not end with a "?".
        # A nil value indicates that the player had no opportunity to make the described bet.
        # For example:
        #   cbet_flop(player)
        #       nil   -- player did not have an opportunity to make a cbet on the flop
        #       true  -- player made a cbet on the flop
        #       false -- player had an opportunity to make a cbet on the flop, but did not
        #
        #   fold_to_flop_2bet(player)
        #       nil   -- player did not have an opportunity to fold to a 2bet on the flop
        #       true  -- player folded to a 2bet on the flop
        #       false -- player had an opportunity to fold to a 2bet on the flop, but did not
        #
        # Some care must be taken in the code and testing to assure the consistency of the nil/false dichotomy
        #
        # They are defined dynamically due to their number and similarities
        #
        
        for street in [:preflop, :flop, :turn, :river]

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
            # make_, call_, and fold_to_ functions, by bet and street street
            #
            for bet in 1..4
                class_eval <<-STREET_AND_BET_FUNCTIONS
                def #{street}_#{bet}bet(player)
                    @street_bets[#{street.inspect}] && @street_bets[#{street.inspect}][#{bet}][player]
                end
                def call_#{street}_#{bet}bet(player)
                    @call_street_bets[#{street.inspect}] && @call_street_bets[#{street.inspect}][#{bet}][player]
                end
                def fold_to_#{street}_#{bet}bet(player)
                    @fold_to_street_bets[#{street.inspect}] && @fold_to_street_bets[#{street.inspect}][#{bet}][player]
                end
                STREET_AND_BET_FUNCTIONS
            end
        end
        
        for street in [:flop, :turn, :river]
            last_street = case street
            when :flop then :preflop
            when :turn then :flop
            when :river then :turn
            end
            
            #
            # make, call_ and fold_to_ cbet and dbet functions, by street
            #
            # cbets (continuation bets) are first-in bets after making last agression on the previous street
            #
            # dbets (donk bets) are first-in bets, made after calling another player's aggression out of position on the previous street
            #

            class_eval <<-FTR_FUNCTIONS
            def cbet_#{street}(player)
                last_aggr_#{last_street}(player) && #{street}_1bet(player)
            end
            def fold_to_cbet_#{street}(player)
                @first_aggr_player[:#{street}] && cbet_#{street}(@first_aggr_player[:#{street}]) && fold_to_#{street}_1bet(player)
                # fold_to_#{street}_1bet(player) && @last_aggr_player[:#{last_street}] && cbet_#{street}(@last_aggr_player[:#{last_street}])
            end
            def call_cbet_#{street}(player)
                @first_aggr_player[:#{street}] && cbet_#{street}(@first_aggr_player[:#{street}]) && call_#{street}_1bet(player)
            end
            def dbet_#{street}(player)
                return nil unless @last_aggr_player[:#{last_street}] && @hand_statistics.betting_order?(player, @last_aggr_player[:#{last_street}])
                #{street}_1bet(player)
            end
            def fold_to_dbet_#{street}(player)
                return nil unless @first_aggr_player[:#{street}] && dbet_#{street}(@first_aggr_player[:#{street}])
                fold_to_#{street}_1bet(player)
            end
            def call_dbet_#{street}(player)
                return nil unless @first_aggr_player[:#{street}] && dbet_#{street}(@first_aggr_player[:#{street}])
                call_#{street}_1bet(player)
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
                @street_bets[each] = [{}, {}, {}, {}, {}] 
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
                if @last_bet.between?(0,3)
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