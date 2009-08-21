require 'rubygems'
require 'activesupport'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/hand_statistics')
require File.expand_path(File.dirname(__FILE__) + '/hand_statistics_spec_helper')

describe HandStatistics, "when created" do
  before(:each) do
    @stats = HandStatistics.new
  end
  it "should return an empty player list" do
    @stats.should have(0).players
  end
  
  it "should properly update hand record information" do
    sample_hand.each{|key, value| @stats.update_hand(key => value)}
    @stats.hand_record.should == sample_hand
  end
  
  it "should properly chain hand record information updates" do
    sample_hand.each{|key, value| @stats.update_hand(key => value)}
    @stats.update_hand(:test => :foo)
    @stats.hand_record.should.should == sample_hand.update(:test => :foo)
  end
    
  it "should not complain when asked to generate hand record with all HAND_INFORMATION_KEYS filled out" do
    lambda{@stats.update_hand(sample_hand).hand_record}.should_not raise_error(/#{HAND_RECORD_INCOMPLETE_MESSAGE}/)
  end
  
  it "should complain when asked to generate hand record if no information is given" do
    lambda{@stats.hand_record}.should raise_error(/#{HAND_RECORD_INCOMPLETE_MESSAGE}/)
  end
  
  HandStatistics::HAND_INFORMATION_KEYS.each do |thing|
    it "should complain when asked to generate hand record without a #{thing.to_s}" do
      lambda{@stats.update_hand(sample_hand.except(thing)).hand_record}.should raise_error(/#{HAND_RECORD_INCOMPLETE_MESSAGE}/)
    end
  end  
end

describe HandStatistics, "when registering game activity" do

  before(:each) do
    @stats = HandStatistics.new
  end

  it "should allow you to register a player" do
    @stats.register_player sample_player
    @stats.should have(1).player_records_without_validation
    @stats.player_records_without_validation.first[:screen_name].should == sample_player[:screen_name]
    @stats.player_records_without_validation.first[:seat].should == sample_player[:seat]
  end
  
  it "should complain when registering a player twice" do
    @stats.register_player sample_player
    lambda{@stats.register_player sample_player}.should raise_error(/#{PLAYER_RECORDS_DUPLICATE_PLAYER_NAME}/)
  end
  
  it "should allow you to register a button" do
    @stats.button.should be_nil
    @stats.register_button(3)
    @stats.button.should == 3
  end
  
  it "should complain when registering action for an unregistered player" do
    lambda {
      @stats.register_action sample_action[:screen_name], sample_action[:action], sample_action
    }.should raise_error(/#{PLAYER_RECORDS_UNREGISTERED_PLAYER}/)
  end

  it "should allow you to register an action" do
    @stats.register_player sample_player
    lambda{@stats.register_action sample_action[:screen_name], sample_action[:action], sample_action}.should_not raise_error
  end
    
  it "should complain when asked to generate player records without a registered player" do
    @stats.register_button(3)
    lambda{@stats.player_records}.should raise_error(PLAYER_RECORDS_NO_PLAYER_REGISTERED)
  end
  
  it "should complain when asked to generate player records without a registered button" do
    @stats.register_player sample_player
    lambda{@stats.player_records}.should raise_error(PLAYER_RECORDS_NO_BUTTON_REGISTERED)
  end
end

describe HandStatistics, "when managing street state" do
  before(:each) do
    @stats = HandStatistics.new
  end
  
  it "should initially have street state set to :prelude" do
    @stats.street.should == :prelude
  end
  
  it "should change street state on an explicit call to #street_transition" do
    @stats.street_transition(:foo)
    @stats.street.should == :foo
  end
  
  it "should not transition when hand_update does not change street state" do
    @stats.should_not_receive(:street_transition)
    @stats.update_hand(:street => :prelude)
  end
  
  it "should transition when hand_update chances to a new state" do
    @stats.should_receive(:street_transition).with(:preflop)
    @stats.update_hand(:street => :preflop)
  end
end

describe HandStatistics, "when evaluating position with three players" do
  before(:each) do
    @stats = HandStatistics.new
    @stats.register_player @seat2 = next_sample_player(:seat => 2, :screen_name => "seat2")
    @stats.register_player @seat4 = next_sample_player(:seat => 4, :screen_name => "seat4")
    @stats.register_player @seat6 = next_sample_player(:seat => 6, :screen_name => "seat6")
  end
  it "should correctly identify position with the button on a chair" do
    @stats.register_button(6)
    @stats.should_not be_cutoff("seat4")
    @stats.should be_button("seat6")
    @stats.should be_sbpos("seat2")
    @stats.should be_bbpos("seat4")
  end
  it "should correctly identify position with the button to the left of the first chair" do
    @stats.register_button(1)
    @stats.should_not be_cutoff("seat4")
    @stats.should be_button("seat6")
    @stats.should be_sbpos("seat2")
    @stats.should be_bbpos("seat4")
  end
  it "should correctly identify position with the button to the right of the last chair" do
    @stats.register_button(9)
    @stats.should_not be_cutoff("seat6")
    @stats.should be_button("seat6")
    @stats.should be_sbpos("seat2")
    @stats.should be_bbpos("seat4")
  end  
  it "should correctly identify position with the button between two middle chairs" do
    @stats.register_button(5)
    @stats.should_not be_cutoff("seat2")
    @stats.should be_button("seat4")
    @stats.should be_sbpos("seat6")
    @stats.should be_bbpos("seat2")
  end
end

describe HandStatistics, "when evaluating position with four players" do
  before(:each) do
    @stats = HandStatistics.new
    @stats.register_player @seat2 = next_sample_player(:seat => 2, :screen_name => "seat2")
    @stats.register_player @seat4 = next_sample_player(:seat => 4, :screen_name => "seat4")
    @stats.register_player @seat6 = next_sample_player(:seat => 6, :screen_name => "seat6")
    @stats.register_player @seat8 = next_sample_player(:seat => 8, :screen_name => "seat8")
  end
  it "should correctly identify position with the button on a chair" do
    @stats.register_button(6)
    @stats.should be_cutoff("seat4")
    @stats.should be_button("seat6")
    @stats.should be_sbpos("seat8")
    @stats.should be_bbpos("seat2")
  end
  it "should correctly identify position with the button to the left of the first chair" do
    @stats.register_button(1)
    @stats.should be_cutoff("seat6")
    @stats.should be_button("seat8")
    @stats.should be_sbpos("seat2")
    @stats.should be_bbpos("seat4")
  end
  it "should correctly identify position with the button to the right of the last chair" do
    @stats.register_button(9)
    @stats.should be_cutoff("seat6")
    @stats.should be_button("seat8")
    @stats.should be_sbpos("seat2")
    @stats.should be_bbpos("seat4")
  end  
  it "should correctly identify position with the button between two middle chairs" do
    @stats.register_button(5)
    @stats.should be_cutoff("seat2")
    @stats.should be_button("seat4")
    @stats.should be_sbpos("seat6")
    @stats.should be_bbpos("seat8")
  end
end

describe HandStatistics, "when managing plugins" do
  before(:each) do
    @hand_statistics = HandStatistics.new
    @plugins = @hand_statistics.plugins
  end
  it "should install specific plugins upon initialization" do
    HandStatistics.new.plugins.map{|each| each.class}.should include(CashStatistics)
  end
  it "should install all the plugins identified upon initialization" do
    HandStatistics.new.plugins.map{|each| each.class}.should include(*HandStatistics.plugin_factory)
  end
  it "should notify plugins whenever there is a street transition" do
    @plugins.each{|each_plugin| each_plugin.should_receive(:street_transition).with(:foo)}
    @hand_statistics.street_transition(:foo)
  end
  it "should notify plugins whenever there is a street transition for a player" do
    @plugins.each{|each_plugin| each_plugin.should_receive(:street_transition_for_player).with(:foo, :bar)}
    @hand_statistics.street_transition_for_player(:foo, :bar)
  end
  it "should notify plugins whenever a player is registered" do
    @plugins.each{|each_plugin| each_plugin.should_receive(:register_player).with("andy", :prelude)}
    @hand_statistics.register_player({:screen_name => "andy"})
  end
end

describe HandStatistics, "when registering standard actions" do
  before(:each) do
    @stats = HandStatistics.new
    @stats.update_hand sample_hand
    @stats.register_player sample_player
    @stats.street_transition :preflop
  end
  
  it "should post correctly" do
    lambda{
      register_post(sample_player, "5".to_d)
    }.should change{@stats.posted(sample_player[:screen_name])}.by("5".to_d)
  end
  
  it "should ante correctly" do
    lambda{
      register_ante(sample_player, "5".to_d)
    }.should change{@stats.posted(sample_player[:screen_name])}.by("5".to_d)
  end
  
  it "should pay correctly" do
    lambda{
      register_bet(sample_player, "5".to_d)
    }.should change{@stats.paid(sample_player[:screen_name])}.by("5".to_d)
  end
  
  it "should win correctly" do
    lambda{
      register_win(sample_player, "5".to_d)
    }.should change{@stats.won(sample_player[:screen_name])}.by("5".to_d)
  end
  
  it "should check correctly" do
    lambda {
      register_check(sample_player)
    }.should_not change{@stats}
  end
  
  it "should fold correctly" do
    lambda {
      register_fold(sample_player)
    }.should_not change{@stats}
  end
  
  it "should show cards correctly" do
    register_cards(sample_player, "AH KH")
    @stats.cards(sample_player[:screen_name]).should == "AH KH"
  end
end

describe HandStatistics, "when registering pay_to actions" do
  before(:each) do
    @stats = HandStatistics.new
    @stats.update_hand sample_hand
    @stats.register_player @first_player = next_sample_player
    @stats.register_player @second_player = next_sample_player
    @stats.register_button @first_player[:seat]
    register_post @first_player, 1
  end
  
  it "should pay_to correctly for regular raise" do
    register_street :preflop
    lambda{
      register_raise_to @second_player, 7
    }.should change{@stats.paid(@second_player[:screen_name])}.by(7)
  end
  
  it "should pay_to correctly for re-raise" do
    @stats.register_action @second_player[:screen_name], "**************", :result => :neutral
    register_post(@second_player, 2)
    register_street :preflop
    lambda{
      register_street :preflop
      register_raise_to @first_player, "7".to_d
    }.should change{@stats.paid(@first_player[:screen_name])}.by("6".to_d)
  end
  
  it "should pay_to correctly for re-raise after new phase" do
    register_post @second_player, "2".to_d
    register_street :flop
    register_bet @first_player, "3".to_d
    lambda{
      register_raise_to @second_player, "7".to_d
    }.should change{@stats.paid(@second_player[:screen_name])}.by("7".to_d)
    lambda{
      #TODO FIX THIS TEST
      @stats.register_action @first_player[:screen_name], "sample_reraise", :result => :pay_to, :amount => "14".to_d
    }.should change{@stats.paid(@first_player[:screen_name])}.by("11".to_d)
  end
end

describe HandStatistics, "when registering pay_to actions after antes" do
  before(:each) do
    @stats = HandStatistics.new
    @stats.update_hand sample_hand
    @stats.register_player @first_player = next_sample_player
    @stats.register_player @second_player = next_sample_player
    register_post @first_player, 1
    register_ante @first_player, 1
    register_ante @second_player, 1
  end
  
  it "should pay_to correctly for regular raise" do
    register_street :preflop
    lambda{
      register_raise_to @second_player, 7
    }.should change{@stats.paid(@second_player[:screen_name])}.by(7)
  end
  
  it "should pay_to correctly for re-raise" do
    @stats.register_action @second_player[:screen_name], "**************", :result => :neutral
    register_post(@second_player, 2)
    register_street :preflop
    lambda{
      register_street :preflop
      register_raise_to @first_player, "7".to_d
    }.should change{@stats.paid(@first_player[:screen_name])}.by("6".to_d)
  end
  
  it "should pay_to correctly for re-raise after new phase" do
    register_post @second_player, "2".to_d
    register_street :flop
    register_bet @first_player, "3".to_d
    lambda{
      register_raise_to @second_player, "7".to_d
    }.should change{@stats.paid(@second_player[:screen_name])}.by("7".to_d)
    lambda{
      #TODO FIX THIS TEST
      @stats.register_action @first_player[:screen_name], "sample_reraise", :result => :pay_to, :amount => "14".to_d
    }.should change{@stats.paid(@first_player[:screen_name])}.by("11".to_d)
  end
end

describe HandStatistics, "when measuring pfr" do
  before(:each) do
    @stats = HandStatistics.new
    @stats.register_player @first_player = next_sample_player
    @stats.register_player @second_player = next_sample_player
    register_post(@first_player, 1)
    register_post(@second_player, 2)
    register_street :preflop
  end
  
  it "should find a pfr opportunity if first actors limped" do
    register_call(@first_player, 1)
    register_check(@second_player)
    @stats.should be_pfr_opportunity(@first_player[:screen_name])
    @stats.should_not be_pfr_opportunity_taken(@first_player[:screen_name])
    @stats.should be_pfr_opportunity(@second_player[:screen_name])
    @stats.should_not be_pfr_opportunity_taken(@second_player[:screen_name])
  end
                              
  it "should not find a pfr opportunity if another player raises first" do
    register_raise_to(@first_player, 5)
    register_call(@second_player, 3)
    @stats.should be_pfr_opportunity(@first_player[:screen_name])
    @stats.should be_pfr_opportunity_taken(@first_player[:screen_name])
    @stats.should_not be_pfr_opportunity(@second_player[:screen_name])
  end
  
  it "should not find a pfr opportunity if player made a raise other than the first raise preflpp" do
    register_raise_to(@first_player, 5)
    register_raise_to(@second_player, 10)
    register_call(@first_player, 5)
    @stats.should be_pfr_opportunity(@first_player[:screen_name])
    @stats.should be_pfr_opportunity_taken(@first_player[:screen_name])
    @stats.should_not be_pfr_opportunity(@second_player[:screen_name])
  end

  it "should be unaffected by postflop bets and raises" do
    register_call(@first_player, 1)
    register_check(@second_player)
    register_street :flop
    register_bet(@first_player, 4)
    register_bet(@second_player, 10)
    register_call(@first_player, 6)
    @stats.should be_pfr_opportunity(@first_player[:screen_name])
    @stats.should be_pfr_opportunity(@second_player[:screen_name])
  end
end

describe HandStatistics, "when measuring aggression" do
  before(:each) do
    @stats = HandStatistics.new
    @stats.register_player @first_player = next_sample_player
    @stats.register_player @second_player = next_sample_player
  end
  
  it "should all have zero values when no actions have been taken" do
    @stats.preflop_passive(@first_player[:screen_name]).should be_zero
    @stats.postflop_passive(@first_player[:screen_name]).should be_zero
    @stats.preflop_aggressive(@first_player[:screen_name]).should be_zero
    @stats.postflop_aggressive(@first_player[:screen_name]).should be_zero
  end
  
  it "should treat a call preflop as a passive move" do
    register_street :preflop
    lambda{register_call(@first_player, 1)}.should change{@stats.preflop_passive(@first_player[:screen_name])}.by(1)
  end
  
  it "should treat a call postflop as a passive move" do
    register_street :flop
    lambda{register_call(@first_player, 1)}.should change{@stats.postflop_passive(@first_player[:screen_name])}.by(1)
  end
  
  it "should treat a raise preflop as an aggressive move" do
    register_street :preflop
    lambda{register_raise_to(@first_player, 7)}.should change{@stats.preflop_aggressive(@first_player[:screen_name])}.by(1)
  end
  
  it "should treat a raise postflop as an aggressive move" do
    register_street :flop
    lambda{register_raise_to(@first_player, 7)}.should change{@stats.postflop_aggressive(@first_player[:screen_name])}.by(1)
  end
  
  it "should treat a bet postflop as an aggressive move" do
    register_street :preflop
    lambda{register_bet(@first_player, 5)}.should change{@stats.preflop_aggressive(@first_player[:screen_name])}.by(1)
  end
  
  it "should not treat a check as an aggressive or a passive move" do
    register_street :preflop
    lambda{register_check(@first_player)}.should_not change{@stats.preflop_aggressive(@first_player[:screen_name])}
    lambda{register_check(@first_player)}.should_not change{@stats.preflop_passive(@first_player[:screen_name])}
    lambda{register_check(@first_player)}.should_not change{@stats.postflop_aggressive(@first_player[:screen_name])}
    lambda{register_check(@first_player)}.should_not change{@stats.postflop_aggressive(@first_player[:screen_name])}
  end
  
  it "should not treat a fold as an aggressive or a passive move" do
    register_street :preflop
    lambda{register_fold(@first_player)}.should_not change{@stats.preflop_aggressive(@first_player[:screen_name])}
    lambda{register_fold(@first_player)}.should_not change{@stats.preflop_passive(@first_player[:screen_name])}
    lambda{register_fold(@first_player)}.should_not change{@stats.postflop_aggressive(@first_player[:screen_name])}
    lambda{register_fold(@first_player)}.should_not change{@stats.postflop_aggressive(@first_player[:screen_name])}
  end  
end

describe HandStatistics, "when measuring c-bets" do
  before(:each) do
    @stats = HandStatistics.new
    @stats.register_player @button = next_sample_player(:screen_name => "button")
    @stats.register_player @sb = next_sample_player(:screen_name => "small blind")
    @stats.register_player @bb = next_sample_player(:screen_name => "big blind")
    @stats.register_button @button[:seat]
    register_street :prelude
    register_post @sb, 1
    register_post @bb, 2
    register_street :preflop
  end
  it "should not find preflop opportunity without a preflop raise" do
    register_call @button, 2
    register_call @sb, 1
    register_check @bb
    register_street :flop
    register_bet @button, 2
    @stats.should_not be_cbet_opportunity(@button[:screen_name])
    @stats.should_not be_cbet_opportunity(@sb[:screen_name])
    @stats.should_not be_cbet_opportunity(@bb[:screen_name])
  end
  it "should not find c-bet opportunity with two preflop raises" do
    register_raise_to @button, 7
    register_raise_to @sb, 14
    register_fold @bb
    register_street :flop
    register_bet @button, 2
    @stats.should_not be_cbet_opportunity(@button[:screen_name])
    @stats.should_not be_cbet_opportunity(@sb[:screen_name])
    @stats.should_not be_cbet_opportunity(@bb[:screen_name])
  end
  it "should not find c-bet opportunity if player raise is not the preflop raiser" do
    register_call @button, 2
    register_raise_to @sb, 7
    register_fold @bb
    register_call @button, 5
    register_street :flop
    register_bet @button, 2
    @stats.should_not be_cbet_opportunity(@button[:screen_name])
  end
  it "should not find c-bet opportunity if non-raiser acts first" do
    register_call @button, 2
    register_raise_to @sb, 7
    register_fold @bb
    register_call @button, 5
    register_street :flop
    register_bet @button, 2
    register_call @sb, 2
    @stats.should_not be_cbet_opportunity(@button[:screen_name])
  end
  
  it "should find c-bet opportunity taken when lone pre-flop raiser makes first-in bet post-flop in position" do
    register_fold @button
    register_call @sb, 1
    register_raise_to @bb, 7
    register_call @sb, 5
    register_street :flop
    register_check @sb
    register_bet @bb, 7
    @stats.should be_cbet_opportunity(@bb[:screen_name])
    @stats.should be_cbet_opportunity_taken(@bb[:screen_name])
    @stats.should_not be_cbet_opportunity(@button[:screen_name])
    @stats.should_not be_cbet_opportunity(@sb[:screen_name])
  end
  it "should find c-bet opportunity taken when lone pre-flop raiser makes first-in bet post-flop out of position" do
    register_fold @button
    register_raise_to @sb, 7
    register_call @bb, 5
    register_street :flop
    register_bet @sb, 7
    @stats.should be_cbet_opportunity(@sb[:screen_name])
    @stats.should be_cbet_opportunity_taken(@sb[:screen_name])
    @stats.should_not be_cbet_opportunity(@button[:screen_name])
    @stats.should_not be_cbet_opportunity(@bb[:screen_name])
  end  
  it "should find c-bet opportunity declined when lone pre-flop raiser does not make first-in bet post-flop in position" do
    register_fold @button
    register_call @sb, 1
    register_raise_to @bb, 7
    register_call @sb, 5
    register_street :flop
    register_check @sb
    register_check @bb
    @stats.should be_cbet_opportunity(@bb[:screen_name])
    @stats.should_not be_cbet_opportunity_taken(@bb[:screen_name])
    @stats.should_not be_cbet_opportunity(@button[:screen_name])
    @stats.should_not be_cbet_opportunity(@sb[:screen_name])
  end
  it "should find c-bet opportunity declined when lone pre-flop raiser does not make first-in bet post-flop out of position" do
    register_fold @button
    register_raise_to @sb, 7
    register_call @bb, 5
    register_street :flop
    register_check @sb
    register_check @bb
    @stats.should be_cbet_opportunity(@sb[:screen_name])
    @stats.should_not be_cbet_opportunity_taken(@sb[:screen_name])
    @stats.should_not be_cbet_opportunity(@button[:screen_name])
    @stats.should_not be_cbet_opportunity(@bb[:screen_name])
  end
end

describe HandStatistics, "when measuring blind attacks" do
  before(:each) do
    @stats = HandStatistics.new
    register_street :prelude
    @stats.register_player @utg = next_sample_player(:screen_name => "utg", :seat => 2)
    @stats.register_player @cutoff = next_sample_player(:screen_name => "cutoff", :seat => 4)
    @stats.register_player @button = next_sample_player(:screen_name => "button", :seat => 6)
    @stats.register_player @sb = next_sample_player(:screen_name => "sb", :seat => 8)
    @stats.register_player @bb = next_sample_player(:screen_name => "bb", :seat => 10)
    @stats.register_button(@button[:seat])
    register_post(@sb, 1)
    register_post(@bb, 2)
    register_street :preflop
  end
  
  it "should identify cutoff opportunities if everybody folds to him" do
    register_fold(@utg)
    register_call(@cutoff, 2)
    register_call(@button, 2)
    register_call(@sb, 1)
    register_check(@bb)
    @stats.should be_blind_attack_opportunity("cutoff")
    @stats.should_not be_blind_attack_opportunity_taken("cutoff")
    @stats.should_not be_blind_attack_opportunity("button")
    @stats.should_not be_blind_attack_opportunity("utg")
    @stats.should_not be_blind_attack_opportunity("sb")
    @stats.should_not be_blind_attack_opportunity("bb")
  end
  
  it "should properly identify cutoff and button opportunities if everybody folds to button" do
    register_fold(@utg)
    register_fold(@cutoff)
    register_call(@button, 2)
    register_call(@sb, 1)
    register_check(@bb)
    @stats.should be_blind_attack_opportunity("cutoff")
    @stats.should_not be_blind_attack_opportunity_taken("cutoff")
    @stats.should be_blind_attack_opportunity("button")
    @stats.should_not be_blind_attack_opportunity_taken("button")
    @stats.should_not be_blind_attack_opportunity("utg")
    @stats.should_not be_blind_attack_opportunity("sb")
    @stats.should_not be_blind_attack_opportunity("bb")
  end

  it "should identify cutoff and button attack opportunities if button raises first-in" do
    register_fold(@utg)
    register_fold(@cutoff)
    register_raise_to(@button, 7)
    register_call(@sb, 6)
    register_fold(@bb)
    register_fold(@utg)
    register_fold(@cutoff)
    @stats.should be_blind_attack_opportunity("cutoff")
    @stats.should_not be_blind_attack_opportunity_taken("cutoff")
    @stats.should be_blind_attack_opportunity("button")
    @stats.should be_blind_attack_opportunity_taken("button")
    @stats.should_not be_blind_attack_opportunity("utg")
    @stats.should_not be_blind_attack_opportunity("sb")
    @stats.should_not be_blind_attack_opportunity("bb")
  end
  
  it "should identify no attack opportunities if utg raises first in" do
    register_raise_to(@utg, 7)
    register_call(@cutoff, 7)
    register_call(@button, 7)
    register_call(@sb, 6)
    register_fold(@bb)
    @stats.should_not be_blind_attack_opportunity("cutoff")
    @stats.should_not be_blind_attack_opportunity("button")
    @stats.should_not be_blind_attack_opportunity("utg")
    @stats.should_not be_blind_attack_opportunity("sb")
    @stats.should_not be_blind_attack_opportunity("bb")
  end
  
  it "should identify attack opportunities only for button if cutoff raises first in" do
    register_raise_to(@utg, 7)
    register_call(@cutoff, 7)
    register_call(@button, 7)
    register_call(@sb, 6)
    register_fold(@bb)
    @stats.should_not be_blind_attack_opportunity("cutoff")
    @stats.should_not be_blind_attack_opportunity("button")
    @stats.should_not be_blind_attack_opportunity("utg")
    @stats.should_not be_blind_attack_opportunity("sb")
    @stats.should_not be_blind_attack_opportunity("bb")
  end
end

describe HandStatistics, "measuring blind defense" do
  before(:each) do
    @stats = HandStatistics.new
    register_street :prelude
    @stats.register_player @utg = next_sample_player(:screen_name => "utg", :seat => 2)
    @stats.register_player @cutoff = next_sample_player(:screen_name => "cutoff", :seat => 4)
    @stats.register_player @button = next_sample_player(:screen_name => "button", :seat => 6)
    @stats.register_player @sb = next_sample_player(:screen_name => "sb", :seat => 8)
    @stats.register_player @bb = next_sample_player(:screen_name => "bb", :seat => 10)
    @stats.register_button(@button[:seat])
    register_post(@sb, 1)
    register_post(@bb, 2)
    register_street :preflop
  end
  
  it "should not identify a blind attack when nobody raises" do
    register_fold(@utg)
    register_call(@cutoff, 2)
    register_call(@button, 2)
    register_call(@sb, 1)
    register_check(@bb)
    @stats.should_not be_blind_defense_opportunity("sb")
    @stats.should_not be_blind_defense_opportunity("bb")
    @stats.should_not be_blind_defense_opportunity("utg")
    @stats.should_not be_blind_defense_opportunity("cutoff")
    @stats.should_not be_blind_defense_opportunity("button")
  end
  
  it "should not identify a blind attack when a non-attacker raises first" do
    register_raise_to(@utg, 7)
    register_fold(@cutoff)
    register_call(@button, 7)
    register_call(@sb, 6)
    register_check(@bb)
    @stats.should_not be_blind_defense_opportunity("sb")
    @stats.should_not be_blind_defense_opportunity("bb")
    @stats.should_not be_blind_defense_opportunity("utg")
    @stats.should_not be_blind_defense_opportunity("cutoff")
    @stats.should_not be_blind_defense_opportunity("button")
  end
  
  it "should not identify a blind attack when a non-attacker raises, even if attacker re-raises" do
    register_raise_to(@utg, 7)
    register_fold(@cutoff)
    register_raise_to(@button, 15)
    register_call(@sb, 14)
    register_call(@bb, 13)
    register_call(@utg, 8)
    @stats.should_not be_blind_defense_opportunity("sb")
    @stats.should_not be_blind_defense_opportunity("bb")
    @stats.should_not be_blind_defense_opportunity("utg")
    @stats.should_not be_blind_defense_opportunity("cutoff")
    @stats.should_not be_blind_defense_opportunity("button")
  end

  it "should identify a blind attack when button raises first-in, taken when blind calls" do
    register_fold(@utg)
    register_fold(@cutoff)
    register_raise_to(@button, 7)
    register_call(@sb, 6)
    register_fold(@bb)
    register_fold(@utg)
    register_fold(@cutoff)
    @stats.should be_blind_defense_opportunity("sb")
    @stats.should be_blind_defense_opportunity_taken("sb")
    @stats.should_not be_blind_defense_opportunity("bb")
    @stats.should_not be_blind_defense_opportunity("utg")
    @stats.should_not be_blind_defense_opportunity("cutoff")
    @stats.should_not be_blind_defense_opportunity("button")
  end

  it "should identify a blind attack when cutoff raises first-in and button folds, not taken on fold, and taken on raise" do
    register_fold(@utg)
    register_raise_to(@cutoff, 7)
    register_fold(@button)
    register_fold(@sb)
    register_raise_to(@bb,200)
    register_fold(@utg)
    register_fold(@cutoff)
    @stats.should be_blind_defense_opportunity("sb")
    @stats.should_not be_blind_defense_opportunity_taken("sb")
    @stats.should be_blind_defense_opportunity("bb")
    @stats.should be_blind_defense_opportunity_taken("bb")
    @stats.should_not be_blind_defense_opportunity("utg")
    @stats.should_not be_blind_defense_opportunity("cutoff")
    @stats.should_not be_blind_defense_opportunity("button")
  end

  it "should not identify a blind attack when cutoff raises first-in and button calls" do
    register_fold(@utg)
    register_raise_to(@cutoff, 7)
    register_call(@button, 7)
    register_call(@sb, 6)
    register_fold(@bb)
    register_fold(@utg)
    @stats.should_not be_blind_defense_opportunity("sb")
    @stats.should_not be_blind_defense_opportunity("bb")
    @stats.should_not be_blind_defense_opportunity("utg")
    @stats.should_not be_blind_defense_opportunity("cutoff")
    @stats.should_not be_blind_defense_opportunity("button")
  end

  it "should not identify a blind attack when cutoff raises first-in and button re-raises" do
    register_fold(@utg)
    register_raise_to(@cutoff, 7)
    register_raise_to(@button, 15)
    register_call(@sb, 6)
    register_fold(@bb)
    register_fold(@utg)
    @stats.should_not be_blind_defense_opportunity("sb")
    @stats.should_not be_blind_defense_opportunity("bb")
    @stats.should_not be_blind_defense_opportunity("utg")
    @stats.should_not be_blind_defense_opportunity("cutoff")
    @stats.should_not be_blind_defense_opportunity("button")
  end  
end

describe HandStatistics, "when reporting statistics" do
  before(:each) do
    @stats = HandStatistics.new
    @stats.register_player @seat2 = next_sample_player(:seat => 2, :screen_name => "seat2")
    @stats.register_player @seat4 = next_sample_player(:seat => 4, :screen_name => "seat4")
    @stats.register_player @seat6 = next_sample_player(:seat => 6, :screen_name => "seat6")
    @stats.register_player @seat8 = next_sample_player(:seat => 8, :screen_name => "seat8")
    @blind_attack_plugin = @stats.plugins.find{|each| each.is_a? BlindAttackStatistics}
    @cash_plugin = @stats.plugins.find{|each| each.is_a? CashStatistics}
    @continuation_bet_plugin = @stats.plugins.find{|each| each.is_a? ContinuationBetStatistics}
    @aggression_plugin = @stats.plugins.find{|each| each.is_a? AggressionStatistics}
    @preflop_raise_plugin = @stats.plugins.find{|each| each.is_a? PreflopRaiseStatistics}
    @reports = {} 
  end

  it "should report blind attack statistics for each player" do
    @blind_attack_plugin.should_receive(:blind_attack_opportunity?).exactly(@stats.players.size)
    @blind_attack_plugin.should_receive(:blind_attack_opportunity_taken?).exactly(@stats.players.size)
    @blind_attack_plugin.should_receive(:blind_defense_opportunity?).exactly(@stats.players.size)
    @blind_attack_plugin.should_receive(:blind_defense_opportunity_taken?).exactly(@stats.players.size)
    @reports = @stats.reports
    @stats.players.each{|each| @reports[each].should include(
        :is_blind_attack_opportunity, 
        :is_blind_attack_opportunity_taken, 
        :is_blind_defense_opportunity, 
        :is_blind_defense_opportunity_taken
    )}
  end
  
  it "should report continuation bet statistics for each player" do
    @continuation_bet_plugin.should_receive(:cbet_opportunity?).exactly(@stats.players.size)
    @continuation_bet_plugin.should_receive(:cbet_opportunity_taken?).exactly(@stats.players.size)
    @reports = @stats.reports
    @stats.players.each{|each| @reports[each].should include(:is_cbet_opportunity)}
    @stats.players.each{|each| @reports[each].should include(:is_cbet_opportunity_taken)}
  end
  
  it "should report cash statistics for each player" do
    @cash_plugin.should_receive(:posted).exactly(@stats.players.size)
    @cash_plugin.should_receive(:paid).exactly(@stats.players.size)
    @cash_plugin.should_receive(:won).exactly(@stats.players.size)
    @cash_plugin.should_receive(:cards).exactly(@stats.players.size)
    @reports = @stats.reports
    @stats.players.each{|each| @reports[each].should include(:posted)}
    @stats.players.each{|each| @reports[each].should include(:paid)}
    @stats.players.each{|each| @reports[each].should include(:won)}
    @stats.players.each{|each| @reports[each].should include(:cards)}
  end
  
  it "should report aggression statistics for each player" do
    @aggression_plugin.should_receive(:preflop_passive).exactly(@stats.players.size)
    @aggression_plugin.should_receive(:preflop_aggressive).exactly(@stats.players.size)
    @aggression_plugin.should_receive(:postflop_passive).exactly(@stats.players.size)
    @aggression_plugin.should_receive(:postflop_aggressive).exactly(@stats.players.size)
    @reports = @stats.reports
    @stats.players.each{|each| @reports[each].should include(:preflop_passive)}
    @stats.players.each{|each| @reports[each].should include(:preflop_aggressive)}
    @stats.players.each{|each| @reports[each].should include(:postflop_passive)}
    @stats.players.each{|each| @reports[each].should include(:postflop_aggressive)}
  end
  
  it "should report preflop raise statistics for each player" do
    @preflop_raise_plugin.should_receive(:pfr_opportunity?).exactly(@stats.players.size)
    @preflop_raise_plugin.should_receive(:pfr_opportunity_taken?).exactly(@stats.players.size)
    @reports = @stats.reports
    @stats.players.each{|each| @reports[each].should include(:is_pfr_opportunity)}
    @stats.players.each{|each| @reports[each].should include(:is_pfr_opportunity_taken)}
  end
end