require 'bigdecimal'
require 'bigdecimal/util'
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/hand_constants')
include HandConstants
  
module HandStatisticsFactories
  def sample_hand
    @@sample_hand_result ||= {
      :session_filename => "a/b/c",
      :starting_at => Time.now,
      :name => "PS0001",
      :description => "This is a description",
      :sb => "1.00".to_d,
      :bb => "2.00".to_d,
      :board => "AS KS QS JS TS",
      :total_pot => "100.00".to_d,
      :rake => "4.00".to_d,
      :played_at => Time.now,
      :tournament => "T123"
    }
  end
  
  def sample_player
    @@sample_player_result ||= {
      :screen_name => 'sample_player_screen_name', 
      :seat => 1
    }
  end
  
  def next_sample_player hash={}
    @@sample_player_count ||= 0
    player = sample_player.clone
    player[:screen_name] = player[:screen_name] + "_" + @@sample_player_count.to_s
    @@sample_player_count += 1
    player.merge(hash)
  end
  
  def sample_action
    @@sample_action_result ||= {
      :state => :prelude,
      :screen_name => sample_player[:screen_name],
      :action => :pay,
      :result => :pay,
      :amount => 10,
      :other_thing => :baz
    }
  end
  
  def register_street(street, hash={})
    @stats.update_hand(hash.merge(:street => street))
  end
  
  def register_bet(player, amount, hash={})
    @stats.register_action player[:screen_name], 'bets', hash.merge(:result => :pay, :amount => amount)
  end
  
  def register_post(player, amount, hash={})
    @stats.register_action player[:screen_name], 'posts', hash.merge(:result => :post, :amount => amount)
  end
  
  def register_ante(player, amount, hash={})
    @stats.register_action player[:screen_name], 'antes', hash.merge(:result => :post, :amount => amount)
  end
  
  def register_raise_to(player, amount, hash={})
    @stats.register_action player[:screen_name], 'raises', hash.merge(:result => :pay_to, :amount => amount)
  end
  
  def register_call(player, amount, hash={})
    @stats.register_action player[:screen_name], 'calls', hash.merge(:result => :pay, :amount => amount)
  end
  
  def register_check(player, hash={})
    @stats.register_action player[:screen_name], 'checks', hash.merge(:result => :neutral)
  end
  
  def register_fold(player, hash={})
    @stats.register_action player[:screen_name], 'folds', hash.merge(:result => :neutral)
  end
  
  def register_win(player, amount, hash={})
    @stats.register_action player[:screen_name], 'wins', hash.merge(:result => :win, :amount => amount)
  end
  
  def register_cards(player, data, hash={})
    @stats.register_action player[:screen_name], 'shows', hash.merge(:result => :cards, :data => data)
  end  
end
include HandStatisticsFactories
