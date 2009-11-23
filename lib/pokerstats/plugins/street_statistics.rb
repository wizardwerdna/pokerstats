module Pokerstats
    class StreetStatistics < HandStatistics::Plugin

        def self.report_specification
          [
            # [key,         sql_type,   function]
            [:saw_flop,     'boolean',  :saw_flop],
            [:saw_turn,     'boolean',  :saw_turn],
            [:saw_river,    'boolean',  :saw_river],
            [:saw_showdown, 'boolean',  :saw_showdown],
            [:won_preflop,  'boolean',  :won_preflop],
            [:won_flop,     'boolean',  :won_flop],
            [:won_turn,     'boolean',  :won_turn],
            [:won_river,    'boolean',  :won_river],
            [:won_showdown, 'boolean',  :won_showdown]
          ]
        end

        def initialize handstatistics
          super handstatistics
          @saw = {}
          @won = {}
        end

        def saw_flop player
            @saw[player] && @saw[player][:flop]
        end

        def saw_turn player
            @saw[player] && @saw[player][:turn]
        end

        def saw_river player
            @saw[player] && @saw[player][:river]
        end

        def saw_showdown player
            @saw[player] && @saw[player][:showdown]
        end

        def won_preflop player
            @won[player] && @won[player][:preflop]
        end

        def won_flop player
            @won[player] && @won[player][:flop]
        end

        def won_turn player
            @won[player] && @won[player][:turn]
        end

        def won_river player
            @won[player] && @won[player][:river]
        end

        def won_showdown player
            @won[player] && @won[player][:showdown]
        end

        def register_player screen_name, street, player
            @saw[screen_name] = {}
            @won[screen_name] = {}
        end

        def street_transition street
        end

        def street_transition_for_player street, player
        end

        def apply_action action, street
            # saw_* statistics for ftrs
            screen_name = action[:screen_name]
            if [:flop, :turn, :river, :showdown].include? street
                @saw[screen_name][street] = true
            end
            # won_* statistics for pftrs
            if [:preflop, :flop, :turn, :river, :showdown].include? street
                if action[:result] == :win
                    @won[screen_name][street] = true
                    if street == :showdown
                        @won[screen_name][@hand_statistics.last_street] = true
                    end
                elsif @won[screen_name][street].nil?
                    @won[screen_name][street] = false
                    if street == :showdown
                        @won[screen_name][@hand_statistics.last_street] = false
                    end
                end
            end
        end
    end
end