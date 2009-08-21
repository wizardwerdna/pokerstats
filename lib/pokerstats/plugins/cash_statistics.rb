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
  
  def cards(player)
    @cards[player]
  end
  
  def self.report_specification
    [
      # [key,   sql_type,   function]
      [:posted, 'decimal',  :posted],
      [:paid,   'decimal',  :paid],
      [:won,    'decimal',  :won],
      [:cards,  'string',   :cards]
    ]
  end
  
  # def report(screen_name)
  #   {
  #     :posted => posted(screen_name),
  #     :paid => paid(screen_name),
  #     :won => won(screen_name),
  #     :cards => cards(screen_name)
  #   }
  # end
  
  def stats(player=nil)
    return @stats unless player
    # @stats.inject({}){|last, pair| last.merge(pair[0] => pair[1][player])}
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
