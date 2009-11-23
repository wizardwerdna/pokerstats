require File.expand_path(File.dirname(__FILE__) + "/../hand_classification")
module Pokerstats
  class CashStatistics < HandStatistics::Plugin
    def initialize handstatistics
      super handstatistics
      @seat = {}
      @posted = {}
      @paid = {}
      @paid_this_round = {}
      @won = {}
      @cards = {}
      @starting_stack = {}
      @stats = {:posted => @posted, :paid => @paid, :won => @won, :cards => @cards}
    end


    def position(player)
        @hand_statistics.position player
    end
    
    def seat(player)
        @seat[player]
    end

    def profit(player)
        return nil unless won(player) && posted(player) && paid(player)
        won(player) - posted(player) - paid(player)
    end
    
    def posted(player)
      @posted[player]
    end
  
    def paid(player)
      @paid[player]
    end
  
    def paid_this_round(player)
      @paid_this_round[player]    
    end
  
    def won(player)
      @won[player]
    end
    
    def divided_by_bb(value)
        bb = @hand_statistics.report_hand_information[:bb]
        return nil if bb.nil? || bb.zero?
        value / (2 * bb)
    end
  
    def profit_in_bb(player)
        divided_by_bb(profit(player))
    end
    
    def posted_in_bb(player)
        divided_by_bb(posted(player))
    end
    
    def paid_in_bb(player)
        divided_by_bb(paid(player))
    end
    
    def won_in_bb(player)
        divided_by_bb(won(player))
    end
  
    def cards(player)
        @cards[player]
    end
    
    def starting_stack(player)
        @starting_stack[player]
    end
    
    def starting_stack_in_bb(player)
        divided_by_bb(starting_stack(player))
    end
    
    def starting_pot
        sb = @hand_statistics.report_hand_information[:sb]
        bb = @hand_statistics.report_hand_information[:bb]
        ante = @hand_statistics.report_hand_information[:ante]
        number_players = @hand_statistics.report_hand_information[:number_players]
        sb && bb && ante && number_players &&
        (sb + bb + ante * number_players)
    end
    
    def starting_stack_as_M(player)
        starting_stack(player) && starting_pot && (starting_pot > 0) && 
        ("1.0".to_d * starting_stack(player) / starting_pot)
    end
    
    def starting_stack_as_M_class(player)
        starting_stack_as_M(player) &&
        case starting_stack_as_M(player)
        when 0 .. 2.99
            "darkred"
        when 2.99 .. 5.99
            "red"
        when 5.99 .. 9.99
            "orange"
        when 9.99 .. 19.99
            "yellow"
        else
            "green"
        end
    end
    
    def card_category_index(player)
      Pokerstats::HandClass.class_index_from_hand_string(cards(player))
    end
  
    def self.report_specification
        [
            # [key,                 sql_type,   function]
            [:seat,                 'integer',  :seat],
            [:position,             'integer',  :position],
            [:posted,               'decimal',  :posted],
            [:paid,                 'decimal',  :paid],
            [:won,                  'decimal',  :won],
            [:profit,               'decimal',  :profit],
            [:posted_in_bb,         'decimal',  :posted_in_bb],
            [:paid_in_bb,           'decimal',  :paid_in_bb],
            [:won_in_bb,            'decimal',  :won_in_bb],
            [:profit_in_bb,         'decimal',  :profit_in_bb],
            [:cards,                'string',   :cards],
            [:card_category_index,  'integer',  :card_category_index],
            [:starting_stack,       'decimal',  :starting_stack],
            [:starting_stack_in_bb, 'decimal',  :starting_stack_in_bb],
            [:starting_stack_as_M, 'decimal',  :starting_stack_as_M],
            [:starting_stack_as_M_class, 'decimal',  :starting_stack_as_M_class]
        ]
    end
  
    def stats(player=nil)
      return @stats unless player
    end
  
    def register_player(screen_name, street, player_hash)
      # puts "register_player(#{screen_name.inspect}, #{street.inspect}, #{player_hash.inspect})"
      @posted[screen_name] = 0
      @paid[screen_name] = 0
      @won[screen_name] = 0
      @starting_stack[screen_name] = player_hash[:starting_stack]
      @seat[screen_name] = player_hash[:seat]
    end
  
    def street_transition_for_player street, player
      @paid_this_round[player] = 0 unless street == :preflop
    end
  
    def apply_action action, street
      player = action[:screen_name]
      description = action[:description]
      result = action[:result]
      amount = action[:amount]
      data = action[:data]
      case result
      when :post
        @posted[player] += amount
        @paid_this_round[player] += amount unless description == "antes"
      when :pay
        @paid[player] ||= 0
        @paid[player] += amount
        @paid_this_round[player] += amount
      when :pay_to
        net_amount_paid = amount - @paid_this_round[player]
        action[:net_amount_paid] = net_amount_paid
        @paid[player] += net_amount_paid
        @paid_this_round[player] += net_amount_paid
      when :win
        @won[player] += amount
      when :neutral
      when :cards
        @cards[player] = data
      else raise "invalid action result: #{result.inspect}"
      end
    end
  end
end