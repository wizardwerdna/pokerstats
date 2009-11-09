module Pokerstats
  class CashStatistics < HandStatistics::Plugin
    def initialize handstatistics
      super handstatistics
      @posted = {}
      @paid = {}
      @paid_this_round = {}
      @won = {}
      @cards = {}
      @stats = {:posted => @posted, :paid => @paid, :won => @won, :cards => @cards}
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
        value / bb
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
    
    def card_category_index(player)
      Pokerstats::class_index_from_hand_string(cards(player))
    end
  
    def self.report_specification
      [
        # [key,   sql_type,   function]
        [:posted,               'decimal',  :posted],
        [:paid,                 'decimal',  :paid],
        [:won,                  'decimal',  :won],
        [:profit,               'decimal',  :profit],
        [:posted_in_bb,         'string',   :posted_in_bb],
        [:paid_in_bb,           'string',   :paid_in_bb],
        [:won_in_bb,            'string',   :won_in_bb],
        [:profit_in_bb,         'string',   :profit_in_bb],
        [:cards,                'string',   :cards],
        [:card_category_index,  'integer',  :card_category_index]
      ]
    end
  
    def stats(player=nil)
      return @stats unless player
    end
  
    def register_player(screen_name, street)
      @posted[screen_name] = 0
      @paid[screen_name] = 0
      @won[screen_name] = 0
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