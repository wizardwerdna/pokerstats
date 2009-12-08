require 'rubygems'
require 'activesupport'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/hand_statistics')
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/hand_classification')
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/pokerstars_hand_history_parser')
include Pokerstats
require File.expand_path(File.dirname(__FILE__) + '/hand_statistics_spec_helper')

Spec::Matchers.define :have_all_and_only_keys do |keylist|
  match do |hash|
    hashkeys = hash.keys
    hashkeys.size == keylist.size && hash.keys.all?{|each_key| keylist.include? each_key}
  end
  failure_message_for_should do |hash|
    "missing keys: #{(keylist - hash.keys).inspect}, extra keys: #{(hash.keys - keylist).inspect}"
  end
  failure_message_for_should_not do |hash|
    "the keys (#{hash.keys.inspect}) are all the same"
  end
  description do
    "have all and only the specified keys"
  end
end

Spec::Matchers.define :have_won_street_statistics_specified_by do |hash_of_hashes|
    match do |hand_statistics|
      @errors = []
      hash_of_hashes.keys.each do |match_player|
          hash_of_hashes[match_player].keys.each do |match_street|
              expected_result = hash_of_hashes[match_player][match_street]
              actual_result = case match_street
                  when :preflop then hand_statistics.won_preflop(match_player)
                  when :flop then hand_statistics.won_flop(match_player)
                  when :turn then hand_statistics.won_turn(match_player)
                  when :river then hand_statistics.won_river(match_player)
                  when :showdown then hand_statistics.won_showdown(match_player)
              end
              unless actual_result == expected_result
                  @errors << {:player => match_player, :street => match_street, :expected => expected_result, :actual => actual_result}
              end
          end
      end
      @errors.empty?
    end
    failure_message_for_should do |hand_statistics|
        @errors.collect do |each| 
            "expected won_#{each[:street]}(#{each[:player].inspect}) to be #{each[:expected].inspect}, obtained #{each[:actual].inspect}"
        end.join("; \n")
    end
    failure_message_for_should_not do |hand_statistics|
    "the actual results conformed to the expected results"
    end
    description do
    "have conforming won_street statistics"
    end
end

Spec::Matchers.define :have_saw_street_statistics_specified_by do |hash_of_hashes|
    match do |hand_statistics|
      @errors = []
      hash_of_hashes.keys.each do |match_player|
          hash_of_hashes[match_player].keys.each do |match_street|
              expected_result = hash_of_hashes[match_player][match_street]
              actual_result = case match_street
                  when :flop then hand_statistics.saw_flop(match_player)
                  when :turn then hand_statistics.saw_turn(match_player)
                  when :river then hand_statistics.saw_river(match_player)
                  when :showdown then hand_statistics.saw_showdown(match_player)
              end
              unless actual_result == expected_result
                  @errors << {:player => match_player, :street => match_street, :expected => expected_result, :actual => actual_result}
              end
          end
      end
      @errors.empty?
    end
    failure_message_for_should do |hand_statistics|
        @errors.collect do |each| 
            "expected saw_#{each[:street]}(#{each[:player].inspect}) to be #{each[:expected].inspect}, obtained #{each[:actual].inspect}"
        end.join("; \n")
    end
    failure_message_for_should_not do |hand_statistics|
    "the actual results conformed to the expected results"
    end
    description do
    "have conforming saw_street statistics"
    end
end

def bet_statistics_proc_symbol(street, bet, prefix = "")
    street_first = case street
        when :preflop then :p
        when :flop then :f
        when :turn then :t
        when :river then :r
    end
    prefix_adjust = case prefix
        when "fold_to_" then "f2_"
        when "call_" then "c_"
        when "" then ""
        else raise "wtf? #{prefix}"
    end
    "#{prefix_adjust}#{street_first}_#{bet}bet".to_s
end

Spec::Matchers.define :have_street_bet_statistics_specified_by do |street_hash, prefix|
    match do |hand_statistics|
        @errors = []
        for match_street in street_hash.keys
            for match_bet in 1..4
                unless match_street == :preflop && match_bet == 1  # no such thing as a preflop 1-bet
                    for match_player in street_hash[match_street][match_bet].keys
                        expected_result = street_hash[match_street][match_bet][match_player]
                        proc_symbol = bet_statistics_proc_symbol(match_street, match_bet, prefix)
                        actual_result = hand_statistics.send(proc_symbol, match_player)
                        unless actual_result == expected_result
                            @errors << {:symbol => proc_symbol, :player => match_player, :expected => expected_result, :actual => actual_result}
                        end
                    end
                end
            end
        end
        @errors.empty?
    end

    failure_message_for_should do |hand_statistics|
        @errors.collect do |each|
            "expected #{each[:symbol]}(#{each[:player].inspect}) to be #{each[:expected].inspect}, obtained #{each[:actual].inspect}"
        end.join("; \n")
    end

    failure_message_for_should_not do |hand_statistics|
        "the actual results conformed to the expected results"
    end

    description do
        "have conforming #{prefix}street_bet statistics"
    end
end

Spec::Matchers.define :have_consistent_street_bet_statistics do
    match do |hand_statistics|
        @errors = []
        for street in [:flop, :turn, :river]
            street_first = case street
                when :preflop then :p
                when :flop then :f
                when :turn then :t
                when :river then :r
            end
            for player in hand_statistics.players
                fs = "f2_#{street_first}_cbet".to_sym
                cs = "c_#{street_first}_cbet".to_sym
                if hand_statistics.send(fs, player).nil? ^ hand_statistics.send(cs, player).nil?
                    @errors << {:fold_symbol => fs, :call_symbol => cs, :player => player}
                end
                fs = "f2_#{street_first}_dbet".to_sym
                cs = "c_#{street_first}_dbet".to_sym
                if hand_statistics.send(fs, player).nil? ^ hand_statistics.send(cs, player).nil?
                    @errors << {:fold_symbol => fs, :call_symbol => cs, :player => player}
                end
            end
            for bet in 1..4
                for player in hand_statistics.players
                    fs = bet_statistics_proc_symbol(street, bet, "fold_to_")
                    cs = bet_statistics_proc_symbol(street, bet, "call_")
                    if hand_statistics.send(fs, player).nil? ^ hand_statistics.send(cs, player).nil?
                        @errors << {:fold_symbol => fs, :call_symbol => cs, :player => player}
                    end
                end
            end
        end
        @errors.empty?
    end

    failure_message_for_should do |hand_statistics|
        @errors.collect do |each|
            "inconsistent results: #{each[:fold_symbol]}(#{each[:player]}) = #{hand_statistics.send(each[:fold_symbol], each[:player]).inspect}," +
            " but #{each[:call_symbol]}(#{each[:player]}) = #{hand_statistics.send(each[:call_symbol], each[:player]).inspect}"
        end.join("; \n")
    end

    failure_message_for_should_not do |hand_statistics|
        "the statistics were consistent"
    end

    description do
        "have consistent call_* and fold_to_* statistics for each player"
    end
end


Spec::Matchers.define :have_last_aggr do |street, screen_name|
    match do |hand_statistics|
        @errors = []
        for player in hand_statistics.players
            actual = hand_statistics.send("last_aggr_#{street}", player)
            expected = if screen_name != player
                nil
            else
                true
            end
            @errors << {:player => player, :expected => expected, :actual => actual} unless expected == actual
        end
        @errors.empty?
    end

    failure_message_for_should do |hand_statistics|
        @errors.collect do |each|
            "expected last_aggr_#{street}(#{each[:player].inspect}) to be #{each[:expected].inspect}, obtained #{each[:actual].inspect}"
        end.join("; \n")
    end

    failure_message_for_should_not do |hand_statistics|
        "the actual results conformed to the expected results"
    end

    description do
        "have conforming last_aggression_#{street} statistics"
    end
end

describe HandStatistics do
    context "when created" do
      before(:each) do
        @stats = HandStatistics.new
      end
  
      it "should return an empty player list" do
        @stats.should have(0).players
      end
  
      it "should properly chain updates of hand record information" do
        sample_hand.each{|key, value| @stats.update_hand(key => value)}
        @stats.hand_record.should == sample_hand
      end
  
      it "should not complain when asked to generate hand record with all HAND_INFORMATION_KEYS filled out" do
        @stats.update_hand(sample_hand)
        lambda{@stats.hand_record}.should_not raise_error(/#{HAND_RECORD_INCOMPLETE_MESSAGE}/)
      end
    
      it "should complain when asked to generate hand record if no information is given" do
        lambda{@stats.hand_record}.should raise_error(/#{HAND_RECORD_INCOMPLETE_MESSAGE}/)
      end
  
      HandStatistics::HAND_INFORMATION_KEYS.each do |thing|
        unless [:ante, :number_players].include?(thing)
            it "should complain when asked to generate hand record without a #{thing.to_s}" do
                @stats.update_hand(sample_hand.except(thing))
                lambda{@stats.hand_record}.should raise_error(/#{HAND_RECORD_INCOMPLETE_MESSAGE}/)
            end
        end
      end  
  
      it "should not produce hand records having extra keys" do
        @stats.update_hand(sample_hand)
        @stats.update_hand(:street => :river)
        @stats.hand_record.should have_all_and_only_keys HAND_INFORMATION_KEYS
      end  
    end

    context "when managing game activity registration" do

      before(:each) do
        @stats = HandStatistics.new
      end

      it "should allow you to register a player" do
        @stats.register_player sample_player
        @stats.should have(1).player_records_without_validation
        @stats.hand_information(:number_players).should == 1
        @stats.player_records_without_validation.first[:screen_name].should == sample_player[:screen_name]
        @stats.player_records_without_validation.first[:seat].should == sample_player[:seat]
        @stats.player_records_without_validation.first[:starting_stack].should == sample_player[:starting_stack]
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

    context "when managing street state" do
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
        
        it "should remember the last street" do
            @stats.last_street.should be_nil
            @stats.street_transition(:foo)
            @stats.last_street.should == :prelude
            @stats.street_transition(:bar)
            @stats.last_street.should == :foo
        end
    end

    context "when managing plugins" do
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
        @plugins.each{|each_plugin| each_plugin.should_receive(:register_player).with("andy", :prelude, {:screen_name => "andy"})}
        @hand_statistics.register_player({:screen_name => "andy"})
      end
    end

    context "when registering standard actions" do
      before(:each) do
        @stats = HandStatistics.new
        @stats.update_hand sample_hand
        @stats.register_player sample_player
        @stats.street_transition :preflop
      end

      it "should post correctly" do
        post_action = lambda{register_post(sample_player, "5".to_d)}
        post_action.should change{@stats.posted(sample_player[:screen_name])}.by("5".to_d)
        post_action.should change{@stats.profit(sample_player[:screen_name])}.by("5".to_d * -1)
        post_action.should change{@stats.posted_in_bb(sample_player[:screen_name])}.by("1.25".to_d)
        post_action.should change{@stats.profit_in_bb(sample_player[:screen_name])}.by("1.25".to_d * -1)
        post_action.should_not change{@stats.paid(sample_player[:screen_name])}
        post_action.should_not change{@stats.won(sample_player[:screen_name])}
      end

      it "should ante correctly" do
        ante_action = lambda{register_ante(sample_player, "5".to_d)}
        ante_action.should change{@stats.posted(sample_player[:screen_name])}.by("5".to_d)
        ante_action.should change{@stats.profit(sample_player[:screen_name])}.by("5".to_d * -1)
        ante_action.should change{@stats.posted_in_bb(sample_player[:screen_name])}.by("1.25".to_d)
        ante_action.should change{@stats.profit_in_bb(sample_player[:screen_name])}.by("1.25".to_d * -1)
        ante_action.should_not change{@stats.paid(sample_player[:screen_name])}
        ante_action.should_not change{@stats.won(sample_player[:screen_name])}
      end

      it "should pay correctly" do
        pay_action = lambda{register_bet(sample_player, "5".to_d)}
        pay_action.should change{@stats.paid(sample_player[:screen_name])}.by("5".to_d)
        pay_action.should change{@stats.profit(sample_player[:screen_name])}.by("5".to_d * -1)
        pay_action.should change{@stats.paid_in_bb(sample_player[:screen_name])}.by("1.25".to_d)
        pay_action.should change{@stats.profit_in_bb(sample_player[:screen_name])}.by("1.25".to_d * -1)
        pay_action.should_not change{@stats.posted(sample_player[:screen_name])}
        pay_action.should_not change{@stats.won(sample_player[:screen_name])}
      end

      it "should win correctly" do
        win_action = lambda{register_win(sample_player, "5".to_d)}
        win_action.should change{@stats.won(sample_player[:screen_name])}.by("5".to_d)
        win_action.should change{@stats.profit(sample_player[:screen_name])}.by("5".to_d)
        win_action.should change{@stats.won_in_bb(sample_player[:screen_name])}.by("1.25".to_d)
        win_action.should change{@stats.profit_in_bb(sample_player[:screen_name])}.by("1.25".to_d)
        win_action.should_not change{@stats.paid(sample_player[:screen_name])}
        win_action.should_not change{@stats.posted(sample_player[:screen_name])}
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
        @stats.card_category_index(sample_player[:screen_name]).should == Pokerstats::class_index_from_hand_string("AH KH")
      end
    end

    context "when registering pay_to actions" do
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

    context "when registering pay_to actions after antes" do
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

    context "when evaluating position" do
        context "with three players" do
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
                @stats.should be_betting_order("seat2", "seat4")
                @stats.should be_betting_order("seat4", "seat6")
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

        context "with four players" do
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
            @stats.should be_betting_order("seat8", "seat2")
            @stats.should be_betting_order("seat2", "seat4")
            @stats.should be_betting_order("seat4", "seat6")
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
    end

    context "when measuring statistics:" do
        context "starting stack data" do
            context "without an ante" do
                before(:each) do
                    @stats = HandStatistics.new
                    @stats.update_hand(sample_hand.merge(:sb => "10".to_d, :bb => "20".to_d, :ante => "0".to_d))
                    @stats.register_player @me = next_sample_player.merge(:screen_name => "me", :starting_stack => "300".to_d)
                end
                it "should compute starting stack statistics correctly" do
                    @stats.starting_stack("me").should == "300".to_d
                    @stats.starting_stack_in_bb("me").should == "7.5".to_d
                    @stats.starting_pot.should == "30".to_d
                    @stats.starting_stack_as_M("me").should == "10".to_d
                    @stats.starting_stack_as_M_class("me").should == "yellow"
                end
            end
            context "with an ante" do
                before(:each) do
                    @stats = HandStatistics.new
                    @stats.update_hand(sample_hand.merge(:sb => "10".to_d, :bb => "20".to_d, :ante => "2".to_d, :number_players => "9".to_d))
                    @stats.register_player @me = next_sample_player.merge(:screen_name => "me", :starting_stack => "300".to_d)
                end
                it "should compute starting stack statistics correctly" do
                    @stats.starting_stack("me").should == "300".to_d
                    @stats.starting_stack_in_bb("me").should == "7.5".to_d
                    @stats.starting_pot.should == "50".to_d
                    @stats.starting_stack_as_M("me").should == "6.0".to_d
                    @stats.starting_stack_as_M_class("me").should == "orange"
                end
            end
        end
 
        context "pfr" do
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

        context "aggression" do
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

        context "c-bets" do
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

        context "blind attacks" do
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

        context "blind defense" do
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

        context "per street" do
            before(:each) do
                @stats = HandStatistics.new
                register_street :prelude
                @stats.register_player @utg = next_sample_player(:screen_name => "utg", :seat => 2)
                @stats.register_player @cutoff = next_sample_player(:screen_name => "cutoff", :seat => 4)
                @stats.register_player @button = next_sample_player(:screen_name => "button", :seat => 6)
                @stats.register_player @sb = next_sample_player(:screen_name => "sb", :seat => 8)
                @stats.register_player @bb = next_sample_player(:screen_name => "bb", :seat => 10)
                @players = [@utg, @cutoff, @button, @sb, @bb]
                @player_names = @players.collect{|each| each[:screen_name]}
                @stats.register_button(@button[:seat])
                register_post(@sb, 1)
                register_post(@bb, 2)
                @players.each{|each| register_ante(each, 0.25)}
                register_street :preflop
                @nil_saw_street_results = {:flop => nil, :turn => nil, :river => nil, :showdown => nil}
                @nil_won_street_results = @nil_saw_street_results.merge(:preflop => nil)
                @saw_street_expected_results = {
                    "utg"       => @nil_saw_street_results.clone,
                    "cutoff"    => @nil_saw_street_results.clone,
                    "button"    => @nil_saw_street_results.clone,
                    "sb"        => @nil_saw_street_results.clone,
                    "bb"        => @nil_saw_street_results.clone
                }
                @won_street_expected_results = {
                    "utg"       => @nil_won_street_results.clone,
                    "cutoff"    => @nil_won_street_results.clone,
                    "button"    => @nil_won_street_results.clone,
                    "sb"        => @nil_won_street_results.clone,
                    "bb"        => @nil_won_street_results.clone
                }
            end
            context "with no action" do
                it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
            end
            context "with preflop action" do
                before(:each) do
                    register_raise_to(@utg, 4)
                    register_raise_to(@cutoff, 8)
                    register_call(@button, 8)
                    register_fold(@sb)
                    for player in ["utg", "cutoff", "button", "sb", "bb"]
                        @won_street_expected_results[player].update(:preflop => false)
                    end
                end
                context "but no winner" do
                    before(:each) do
                        register_fold(@bb)
                        register_call(@utg,4)
                    end
                    it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                    it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
                end
                context "and an uncontested winner" do
                    before(:each) do
                        register_raise_to(@bb, 100)
                        register_fold(@utg)
                        register_fold(@cutoff)
                        register_fold(@button)
                        register_win(@bb, 9.25)
                        @won_street_expected_results["bb"][:preflop] = true
                    end
                    it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                    it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
                end
                context "and a showdown" do
                    before(:each) do
                        register_raise_to(@bb, 100)
                        register_fold(@utg)
                        register_fold(@cutoff)
                        register_call(@button, 100)
                        register_street(:showdown)
                        register_muck(@button)
                        register_win(@bb, 9.25)
                        @won_street_expected_results["bb"][:preflop] = true
                        @won_street_expected_results["bb"][:showdown] = true
                        @won_street_expected_results["button"][:showdown] = false
                        @saw_street_expected_results["bb"][:showdown] = true
                        @saw_street_expected_results["button"][:showdown] = true
                    end
                    it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                    it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
                end
                context ", flop action" do
                    before(:each) do
                        register_call(@bb, 6)
                        register_call(@utg, 4)
                        register_street(:flop)
                        register_check(@utg)
                        register_bet(@cutoff, 10)
                        register_fold(@button)
                        ["utg", "cutoff", "button", "bb"].each{|each|@saw_street_expected_results[each][:flop] = true}
                        ["utg", "cutoff", "button", "bb"].each{|each|@won_street_expected_results[each][:flop] = false}
                    end
                    context "but no winner" do
                        before(:each) do
                            register_raise_to(@bb, 20)
                            register_call(@utg, 14)
                            register_call(@cutoff, 10)
                        end
                        it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                        it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
                    end
                    context "and an uncontested winner" do
                        before(:each) do
                            register_fold(@bb)
                            register_fold(@utg)
                            register_win(@cutoff, 20)
                            ["utg", "cutoff", "button", "bb"].each{|each|@won_street_expected_results[each][:flop] = (each=="cutoff")}
                        end
                        it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                        it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
                    end
                    context "and a showdown" do
                        before(:each) do
                            register_fold(@bb)
                            register_call(@utg, 10)
                            register_street(:showdown)
                            register_muck(@cutoff)
                            register_win(@button, 20)
                            ["utg", "cutoff", "button", "bb"].each{|each|@won_street_expected_results[each][:flop] = (each=="button")}
                            ["cutoff", "button"].each{|each|@saw_street_expected_results[each][:showdown] = true}
                            ["cutoff", "button"].each{|each|@won_street_expected_results[each][:showdown] = (each=="button")}
                        end
                        it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                        it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
                    end
                    context ", turn action" do
                        before(:each) do
                            register_call(@bb, 10)
                            register_call(@utg, 10)
                            register_street(:turn)
                            register_check(@bb)
                            register_bet(@utg, 10)
                            register_fold(@cutoff)
                            ["utg", "cutoff", "bb"].each{|each|@saw_street_expected_results[each][:turn] = true}
                            ["utg", "cutoff", "bb"].each{|each|@won_street_expected_results[each][:turn] = false}
                        end
                        context "but no winner" do
                            before(:each) do
                                register_call(@bb, 10)
                            end
                            it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                            it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
                        end
                        context "and an uncontested winner" do
                            before(:each) do
                                register_fold(@bb)
                                register_win(@utg, 20)
                                @won_street_expected_results["utg"][:turn] = true
                            end
                            it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                            it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
                        end
                        context "and a showdown" do
                            before(:each) do
                                register_call(@bb, 10)
                                register_street(:showdown)
                                register_muck(@utg)
                                register_win(@bb, 20)
                                @won_street_expected_results["bb"][:turn] = true
                                @saw_street_expected_results["bb"][:showdown] = true
                                @saw_street_expected_results["utg"][:showdown] = true
                                @won_street_expected_results["bb"][:showdown] = true
                                @won_street_expected_results["utg"][:showdown] = false
                            end
                            it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                            it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
                        end
                        context ", river action" do
                            before(:each) do
                                register_call(@bb, 10)
                                register_street(:river)
                                register_check(@bb)
                                register_bet(@utg, 10)
                                ["utg", "cutoff", "bb"].each{|each|@saw_street_expected_results[each][:river] = true}
                                ["utg", "cutoff", "bb"].each{|each|@won_street_expected_results[each][:river] = false}
                            end
                            context "but no winner" do
                                before(:each) do
                                    register_call(@cutoff, 10)
                                end
                                it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                                it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
                            end
                            context "and an uncontested winner" do
                                before(:each) do
                                    register_fold(@cutoff)
                                    register_win(@utg, 10)
                                    @won_street_expected_results["utg"][:river] = true
                                    @won_street_expected_results["cutoff"][:river] = false
                                end
                                it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                                it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
                            end
                            context "and a showdown" do
                                before(:each) do
                                    register_call(@cutoff, 10)
                                    register_street(:showdown)
                                    register_muck(@cutoff)
                                    register_win(@utg, 10)
                                    @won_street_expected_results["utg"][:river] = true
                                    @won_street_expected_results["cutoff"][:river] = false
                                    @saw_street_expected_results["utg"][:showdown] = true
                                    @saw_street_expected_results["cutoff"][:showdown] = true
                                    @won_street_expected_results["utg"][:showdown] = true
                                    @won_street_expected_results["cutoff"][:showdown] = false
                                end
                                it {@stats.should have_saw_street_statistics_specified_by @saw_street_expected_results}
                                it {@stats.should have_won_street_statistics_specified_by @won_street_expected_results}
                            end
                        end
                    end
                end
            end
        end

        context "bet and raises by street" do
            before(:each) do
                @stats = HandStatistics.new
                register_street :prelude
                @stats.register_player @utg = next_sample_player(:screen_name => "utg", :seat => 2)
                @stats.register_player @cutoff = next_sample_player(:screen_name => "cutoff", :seat => 4)
                @stats.register_player @button = next_sample_player(:screen_name => "button", :seat => 6)
                @stats.register_player @sb = next_sample_player(:screen_name => "sb", :seat => 8)
                @stats.register_player @bb = next_sample_player(:screen_name => "bb", :seat => 10)
                @players = [@utg, @cutoff, @button, @sb, @bb]
                @player_names = @players.collect{|each| each[:screen_name]}
                @bet_specification = {}
                @call_bet_specification = {}
                @fold_to_bet_specification = {}
                for street in [:preflop, :flop, :turn, :river]
                    @bet_specification[street] = []
                    @call_bet_specification[street] = []
                    @fold_to_bet_specification[street] = []
                    for bet in 1..4
                        @bet_specification[street][bet] = {}
                        @call_bet_specification[street][bet] = {}
                        @fold_to_bet_specification[street][bet] = {}
                        for player in @player_names
                            @bet_specification[street][bet][player] = nil
                            @call_bet_specification[street][bet][player] = nil
                            @fold_to_bet_specification[street][bet][player] = nil
                        end
                    end
                end
                @stats.register_button(@button[:seat])
                register_post(@sb, 1)
                register_post(@bb, 2)
                @players.each{|each| register_ante(each, 0.25)}
                register_street :preflop
            end
            context "with no raising" do
                before(:each) do
                    [:flop, :turn, :river].each do |street|
                        register_street street
                        register_check(@sb)
                        register_check(@bb)
                        register_bet(@utg, 5)
                        register_call(@cutoff, 5)
                        register_fold(@button)
                        @bet_specification[street][1]["sb"] = false
                        @bet_specification[street][1]["bb"] = false
                        @bet_specification[street][1]["utg"] = true
                        @call_bet_specification[street][1]["cutoff"] = true
                        @call_bet_specification[street][1]["button"] = false
                        @fold_to_bet_specification[street][1]["cutoff"] = false
                        @fold_to_bet_specification[street][1]["button"] = true
                        @bet_specification[street][2]["cutoff"] = false
                        @bet_specification[street][2]["button"] = false
                        @stats.should have_last_aggr(street, "utg")
                    end
                end
                it {@stats.should have_street_bet_statistics_specified_by @bet_specification, ""}
                it {@stats.should have_street_bet_statistics_specified_by @call_bet_specification, "call_"}
                it {@stats.should have_street_bet_statistics_specified_by @fold_to_bet_specification, "fold_to_"}
                it {@stats.should have_consistent_street_bet_statistics}
            end
            
            context "after 1 raise" do
                context "preflop" do
                    before(:each) do
                        register_call(@utg, 2)
                        register_fold(@cutoff)
                        register_raise_to(@button, 5)
                        register_call(@sb, 4)
                        register_fold(@bb)
                        @call_bet_specification[:preflop][1]["utg"] = true
                        @fold_to_bet_specification[:preflop][1]["utg"] = false
                        @bet_specification[:preflop][2]["utg"] = false
                        @call_bet_specification[:preflop][1]["cutoff"] = false
                        @fold_to_bet_specification[:preflop][1]["cutoff"] = true
                        @bet_specification[:preflop][2]["cutoff"] = false
                        @call_bet_specification[:preflop][1]["button"] = false
                        @fold_to_bet_specification[:preflop][1]["button"] = false
                        @bet_specification[:preflop][2]["button"] = true
                        @call_bet_specification[:preflop][2]["sb"] = true
                        @fold_to_bet_specification[:preflop][2]["sb"] = false
                        @bet_specification[:preflop][3]["sb"] = false
                        @call_bet_specification[:preflop][2]["bb"] = false
                        @fold_to_bet_specification[:preflop][2]["bb"] = true
                        @bet_specification[:preflop][3]["bb"] = false
                        @stats.should have_last_aggr(:preflop, "button")
                    end
                    it {@stats.should have_street_bet_statistics_specified_by @bet_specification, ""}
                    it {@stats.should have_street_bet_statistics_specified_by @call_bet_specification, "call_"}
                    it {@stats.should have_street_bet_statistics_specified_by @fold_to_bet_specification, "fold_to_"}
                    it {@stats.should have_consistent_street_bet_statistics}
                end
                context "other streets" do
                    before(:each) do
                        [:flop, :turn, :river].each do |street|
                            register_street street
                            register_bet(@utg, 5)
                            register_raise_to(@cutoff, 10)
                            register_fold(@button)
                            register_call(@sb, 10)
                            register_raise_to(@bb, 20)
                            @bet_specification[street][1]["utg"] = true
                            @call_bet_specification[street][1]["cutoff"] = false
                            @fold_to_bet_specification[street][1]["cutoff"] = false
                            @bet_specification[street][2]["cutoff"] = true
                            @call_bet_specification[street][2]["button"] = false
                            @fold_to_bet_specification[street][2]["button"] = true
                            @bet_specification[street][3]["button"] = false
                            @call_bet_specification[street][2]["sb"] = true
                            @fold_to_bet_specification[street][2]["sb"] = false
                            @bet_specification[street][3]["sb"] = false
                            @call_bet_specification[street][2]["bb"] = false
                            @fold_to_bet_specification[street][2]["bb"] = false
                            @bet_specification[street][3]["bb"] = true
                            @stats.should have_last_aggr(street, "bb")
                        end
                    end
                    it {@stats.should have_street_bet_statistics_specified_by @bet_specification, ""}
                    it {@stats.should have_street_bet_statistics_specified_by @call_bet_specification, "call_"}
                    it {@stats.should have_street_bet_statistics_specified_by @fold_to_bet_specification, "fold_to_"}
                    it {@stats.should have_consistent_street_bet_statistics}
                end
            end
            
            context "after 2 raises" do
                context "preflop" do
                    before(:each) do
                        register_raise_to(@utg, 10)
                        register_raise_to(@cutoff, 20)
                        register_fold(@button)
                        register_call(@sb, 19)
                        register_raise_to(@bb, 50)
                        @call_bet_specification[:preflop][1]["utg"] = false
                        @fold_to_bet_specification[:preflop][1]["utg"] = false
                        @bet_specification[:preflop][2]["utg"] = true
                        @call_bet_specification[:preflop][2]["cutoff"] = false
                        @fold_to_bet_specification[:preflop][2]["cutoff"] = false
                        @bet_specification[:preflop][3]["cutoff"] = true
                        @call_bet_specification[:preflop][3]["button"] = false
                        @fold_to_bet_specification[:preflop][3]["button"] = true
                        @bet_specification[:preflop][4]["button"] = false
                        @call_bet_specification[:preflop][3]["sb"] = true
                        @fold_to_bet_specification[:preflop][3]["sb"] = false
                        @bet_specification[:preflop][4]["sb"] = false
                        @call_bet_specification[:preflop][3]["bb"] = false
                        @fold_to_bet_specification[:preflop][3]["bb"] = false
                        @bet_specification[:preflop][4]["bb"] = true
                        @stats.should have_last_aggr(:preflop, "bb")
                    end
                    it {@stats.should have_street_bet_statistics_specified_by @bet_specification, ""}
                    it {@stats.should have_street_bet_statistics_specified_by @call_bet_specification, "call_"}
                    it {@stats.should have_street_bet_statistics_specified_by @fold_to_bet_specification, "fold_to_"}
                    it {@stats.should have_consistent_street_bet_statistics}
                end
                context "other streets" do
                    before(:each) do
                        [:flop, :turn, :river].each do |street|
                            register_street street
                            register_bet(@sb, 5)
                            register_raise_to(@bb, 10)
                            register_raise_to(@utg, 50)
                            register_fold(@cutoff)
                            register_call(@button, 50)
                            register_raise_to(@sb, 250)
                            @bet_specification[street][1]["sb"] = true
                            @call_bet_specification[street][1]["bb"] = false
                            @fold_to_bet_specification[street][1]["bb"] = false
                            @bet_specification[street][2]["bb"] = true
                            @call_bet_specification[street][2]["utg"] = false
                            @fold_to_bet_specification[street][2]["utg"] = false
                            @bet_specification[street][3]["utg"] = true
                            @call_bet_specification[street][3]["cutoff"] = false
                            @fold_to_bet_specification[street][3]["cutoff"] = true
                            @bet_specification[street][4]["cutoff"] = false
                            @call_bet_specification[street][3]["button"] = true
                            @fold_to_bet_specification[street][3]["button"] = false
                            @bet_specification[street][4]["button"] = false
                            @call_bet_specification[street][3]["sb"] = false
                            @fold_to_bet_specification[street][3]["sb"] = false
                            @bet_specification[street][4]["sb"] = true
                            @stats.should have_last_aggr(street,"sb")
                        end
                    end
                    it {@stats.should have_street_bet_statistics_specified_by @bet_specification, ""}
                    it {@stats.should have_street_bet_statistics_specified_by @call_bet_specification, "call_"}
                    it {@stats.should have_street_bet_statistics_specified_by @fold_to_bet_specification, "fold_to_"}
                    it {@stats.should have_consistent_street_bet_statistics}
                end
            end
            
            context "after 3 raises" do
                context "preflop" do
                    before(:each) do
                        register_raise_to(@utg, 10)
                        register_raise_to(@cutoff, 50)
                        register_raise_to(@button, 150)
                        register_fold(@sb)
                        register_call(@bb, 148)
                        register_raise_to(@utg, 480)
                        @call_bet_specification[:preflop][1]["utg"] = false
                        @fold_to_bet_specification[:preflop][1]["utg"] = false
                        @bet_specification[:preflop][2]["utg"] = true
                        @call_bet_specification[:preflop][2]["cutoff"] = false
                        @fold_to_bet_specification[:preflop][2]["cutoff"] = false
                        @bet_specification[:preflop][3]["cutoff"] = true
                        @call_bet_specification[:preflop][3]["button"] = false
                        @fold_to_bet_specification[:preflop][3]["button"] = false
                        @bet_specification[:preflop][4]["button"] = true
                        @call_bet_specification[:preflop][4]["sb"] = false
                        @call_bet_specification[:preflop][4]["bb"] = true
                        @call_bet_specification[:preflop][4]["utg"] = false
                        @fold_to_bet_specification[:preflop][4]["sb"] = true
                        @fold_to_bet_specification[:preflop][4]["bb"] = false
                        @fold_to_bet_specification[:preflop][4]["utg"] = false
                        @stats.should have_last_aggr(:preflop, "utg")
                    end
                    it {@stats.should have_street_bet_statistics_specified_by @bet_specification, ""}
                    it {@stats.should have_street_bet_statistics_specified_by @call_bet_specification, "call_"}
                    it {@stats.should have_street_bet_statistics_specified_by @fold_to_bet_specification, "fold_to_"}
                    it {@stats.should have_consistent_street_bet_statistics}
                end
                context "other streets" do
                    before(:each) do
                        [:flop, :turn, :river].each do |street|
                            register_street street
                            register_bet(@sb, 5)
                            register_raise_to(@bb, 10)
                            register_raise_to(@utg, 50)
                            register_raise_to(@cutoff, 150)
                            register_fold(@button)
                            register_call(@sb, 145)
                            register_raise_to(@bb, 450)
                            @bet_specification[street][1]["sb"] = true
                            @call_bet_specification[street][1]["bb"] = false
                            @fold_to_bet_specification[street][1]["bb"] = false
                            @bet_specification[street][2]["bb"] = true
                            @call_bet_specification[street][2]["utg"] = false
                            @fold_to_bet_specification[street][2]["utg"] = false
                            @bet_specification[street][3]["utg"] = true
                            @call_bet_specification[street][3]["cutoff"] = false
                            @fold_to_bet_specification[street][3]["cutoff"] = false
                            @bet_specification[street][4]["cutoff"] = true
                            @call_bet_specification[street][4]["button"] = false
                            @call_bet_specification[street][4]["sb"] = true
                            @call_bet_specification[street][4]["bb"] = false
                            @fold_to_bet_specification[street][4]["button"] = true
                            @fold_to_bet_specification[street][4]["sb"] = false
                            @fold_to_bet_specification[street][4]["bb"] = false
                            @stats.should have_last_aggr(street, "bb")
                        end
                    end
                    it {@stats.should have_street_bet_statistics_specified_by @bet_specification, ""}
                    it {@stats.should have_street_bet_statistics_specified_by @call_bet_specification, "call_"}
                    it {@stats.should have_street_bet_statistics_specified_by @fold_to_bet_specification, "fold_to_"}
                    it {@stats.should have_consistent_street_bet_statistics}
                end
            end
            
            context "after 4 raises" do
                context "preflop" do
                    before(:each) do
                        register_raise_to(@utg, 10)
                        register_raise_to(@cutoff, 50)
                        register_raise_to(@button, 150)
                        register_raise_to(@sb, 500)
                        register_fold(@bb)
                        register_call(@utg, 490)
                        register_raise_to(@utg, 1000)
                        @call_bet_specification[:preflop][1]["utg"] = false
                        @fold_to_bet_specification[:preflop][1]["utg"] = false
                        @bet_specification[:preflop][2]["utg"] = true
                        @call_bet_specification[:preflop][2]["cutoff"] = false
                        @fold_to_bet_specification[:preflop][2]["cutoff"] = false
                        @bet_specification[:preflop][3]["cutoff"] = true
                        @call_bet_specification[:preflop][3]["button"] = false
                        @fold_to_bet_specification[:preflop][3]["button"] = false
                        @bet_specification[:preflop][4]["button"] = true
                        @call_bet_specification[:preflop][4]["sb"] = false
                        @fold_to_bet_specification[:preflop][4]["sb"] = false
                        @stats.should have_last_aggr(:preflop, "utg")
                    end
                    it {@stats.should have_street_bet_statistics_specified_by @bet_specification, ""}
                    it {@stats.should have_street_bet_statistics_specified_by @call_bet_specification, "call_"}
                    it {@stats.should have_street_bet_statistics_specified_by @fold_to_bet_specification, "fold_to_"}
                    it {@stats.should have_consistent_street_bet_statistics}
                end
                context "other streets" do
                    before(:each) do
                        [:flop, :turn, :river].each do |street|
                            register_street street
                            register_bet(@sb, 5)
                            register_raise_to(@bb, 10)
                            register_raise_to(@utg, 50)
                            register_raise_to(@cutoff, 150)
                            register_raise_to(@button, 500)
                            register_fold(@sb)
                            register_call(@bb, 490)
                            register_raise_to(@utg,1000)
                            @bet_specification[street][1]["sb"] = true
                            @call_bet_specification[street][1]["bb"] = false
                            @fold_to_bet_specification[street][1]["bb"] = false
                            @bet_specification[street][2]["bb"] = true
                            @call_bet_specification[street][2]["utg"] = false
                            @fold_to_bet_specification[street][2]["utg"] = false
                            @bet_specification[street][3]["utg"] = true
                            @call_bet_specification[street][3]["cutoff"] = false
                            @fold_to_bet_specification[street][3]["cutoff"] = false
                            @bet_specification[street][4]["cutoff"] = true
                            @call_bet_specification[street][4]["button"] = false
                            @fold_to_bet_specification[street][4]["button"] = false
                            @stats.should have_last_aggr(street, "utg")
                        end
                    end
                    it {@stats.should have_street_bet_statistics_specified_by @bet_specification, ""}
                    it {@stats.should have_street_bet_statistics_specified_by @call_bet_specification, "call_"}
                    it {@stats.should have_street_bet_statistics_specified_by @fold_to_bet_specification, "fold_to_"}
                    it {@stats.should have_consistent_street_bet_statistics}
                end
            end            
        end

        context "cbets and dbets by street" do
            before(:each) do
                @stats = HandStatistics.new
                @stats.register_player @button = next_sample_player(:screen_name => "button")
                @stats.register_player @sb = next_sample_player(:screen_name => "sb")
                @stats.register_player @bb = next_sample_player(:screen_name => "bb")
                @stats.register_button @button[:seat]
                register_street :prelude
                register_post @sb, 1
                register_post @bb, 2
                register_street :preflop
            end

            it "should not find cbet or dbet opportunity without a raise on the prior street" do
                register_call @button, 2
                register_call @sb, 1
                register_check @bb
                register_street :flop
                register_check @sb
                register_check @bb
                register_bet @button, 2
                ["sb", "bb", "button"].each do |player|
                    @stats.f_cbet(player).should be_nil
                    @stats.c_f_cbet(player).should be_nil
                    @stats.f2_f_cbet(player).should be_nil
                    @stats.f_dbet(player).should be_nil
                    @stats.c_f_dbet(player).should be_nil
                    @stats.f2_f_dbet(player).should be_nil
                end
                @stats.should have_consistent_street_bet_statistics
            end

            context "when button last bets each street and bets first in on the next" do
                before(:each) do
                    [:flop, :turn, :river].each do |street|
                        if street == :flop
                            register_raise_to(@button, 100)
                            register_call(@sb, 99)
                            register_call(@bb, 98)
                        end
                        register_street street
                        register_check(@sb)
                        register_check(@bb)
                        register_bet(@button, 100)
                        register_call(@sb, 100)
                        register_fold(@bb)
                    end
                end
                it "should correctly compute cbet stats" do
                    [:f, :t, :r].each do |street|
                        @stats.send("#{street}_cbet", "sb").should be_nil
                        @stats.send("#{street}_cbet", "bb").should be_nil
                        @stats.send("#{street}_cbet", "button").should be_true
                        @stats.send("c_#{street}_cbet", "sb").should be_true
                        @stats.send("c_#{street}_cbet", "bb").should be_false
                        @stats.send("c_#{street}_cbet", "button").should be_nil
                        @stats.send("f2_#{street}_cbet", "sb").should be_false
                        @stats.send("f2_#{street}_cbet", "bb").should be_true
                        @stats.send("f2_#{street}_cbet", "button").should be_nil
                        @stats.send("#{street}_dbet", "sb").should be_false
                        @stats.send("#{street}_dbet", "bb").should be_false
                        @stats.send("#{street}_dbet", "button").should be_nil
                        [:sb, :bb, :button].each do |player|
                            @stats.send("c_#{street}_dbet", "sb").should be_nil
                            @stats.send("f2_#{street}_dbet", "bb").should be_nil
                        end
                        @stats.should have_consistent_street_bet_statistics
                    end
                end
            end

            context "when button last bets each street and bb donk bets" do
                before(:each) do
                    [:flop, :turn, :river].each do |street|
                        if street == :flop
                            register_raise_to(@button, 100)
                            register_call(@sb, 99)
                            register_call(@bb, 98)
                        end
                        register_street street
                        register_check(@sb)
                        register_bet(@bb, 100)
                        register_raise_to(@button, 200)
                        register_fold(@sb)
                        register_call(@sb, 100)
                    end
                end
                it "should correctly compute cbet stats" do
                    [:f, :t, :r].each do |street|
                        [:sb, :bb, :button].each do |player|
                            @stats.send("#{street}_cbet", player).should be_nil
                            @stats.send("c_#{street}_cbet", player).should be_nil
                            @stats.send("f2_#{street}_cbet", player).should be_nil
                        end
                        @stats.send("#{street}_dbet", "sb").should be_false
                        @stats.send("#{street}_dbet", "bb").should be_true
                        @stats.send("#{street}_dbet", "button").should be_nil
                        @stats.send("c_#{street}_dbet", "sb").should be_nil
                        @stats.send("c_#{street}_dbet", "bb").should be_nil
                        @stats.send("c_#{street}_dbet", "button").should be_false
                        @stats.send("f2_#{street}_dbet", "sb").should be_nil
                        @stats.send("f2_#{street}_dbet", "bb").should be_nil
                        @stats.send("f2_#{street}_dbet", "button").should be_false
                        @stats.should have_consistent_street_bet_statistics
                    end
                end
            end

            context "when big blind last bets each street and bets first in on the next" do
                before(:each) do
                    [:flop, :turn, :river].each do |street|
                        if street == :flop
                            register_call(@button, 2)
                            register_call(@sb, 1)
                            register_raise_to(@bb, 100)
                            register_call(@button, 98)
                            register_call(@sb, 98)
                        end
                        register_street street
                        register_check(@sb)
                        register_bet(@bb, 100)
                        register_call(@button, 100)
                        register_fold(@sb)
                    end
                end
                it "should correctly compute cbet stats" do
                    [:f, :t, :r].each do |street|
                        @stats.send("#{street}_cbet", "sb").should be_nil
                        @stats.send("#{street}_cbet", "bb").should be_true
                        @stats.send("#{street}_cbet", "button").should be_nil
                        @stats.send("c_#{street}_cbet", "sb").should be_false
                        @stats.send("c_#{street}_cbet", "bb").should be_nil
                        @stats.send("c_#{street}_cbet", "button").should be_true
                        @stats.send("f2_#{street}_cbet", "sb").should be_true
                        @stats.send("f2_#{street}_cbet", "bb").should be_nil
                        @stats.send("f2_#{street}_cbet", "button").should be_false
                        @stats.send("#{street}_dbet", "sb").should be_false
                        @stats.send("#{street}_dbet", "bb").should be_nil
                        @stats.send("#{street}_dbet", "button").should be_nil
                        [:sb, :bb, :button].each do |player|
                            @stats.send("c_#{street}_dbet", "sb").should be_nil
                            @stats.send("f2_#{street}_dbet", "bb").should be_nil
                        end
                        @stats.should have_consistent_street_bet_statistics
                    end
                end
            end
            
            context "when button is last aggressor preflop and checks on flop" do
                before(:each) do
                    register_raise_to(@button, 100)
                    register_call(@sb, 99)
                    register_call(@bb, 98)
                    register_street :flop
                    register_check(@sb)
                    register_check(@bb)
                    register_check(@button)
                end
                
                it "correctly compute cbet stats" do
                    @stats.f_cbet("sb").should be_nil
                    @stats.f_cbet("bb").should be_nil
                    @stats.f_cbet("button").should be_false
                    ["sb", "bb", "button"].each do |player|
                        @stats.send("c_f_cbet", player).should be_nil
                        @stats.send("f2_f_cbet", player).should be_nil
                    end
                    @stats.f_dbet("sb").should be_false
                    @stats.f_dbet("bb").should be_false
                    @stats.f_dbet("button").should be_nil
                    [:sb, :bb, :button].each do |player|
                        @stats.f_dbet(player).should be_nil
                    end
                    @stats.should have_consistent_street_bet_statistics
                end
            end
            
            context "when button is last aggressor flop and checks on turn" do
                before(:each) do
                    register_street :flop
                    register_check(@sb)
                    register_check(@bb)
                    register_bet(@button, 100)
                    register_call(@sb, 100)
                    register_call(@bb, 100)
                    register_street :turn
                    register_check(@sb)
                    register_check(@bb)
                    register_check(@button)
                end
                
                it "correctly compute cbet stats" do
                    @stats.t_cbet("sb").should be_nil
                    @stats.t_cbet("bb").should be_nil
                    @stats.t_cbet("button").should be_false
                    ["sb", "bb", "button"].each do |player|
                        @stats.send("c_t_cbet", player).should be_nil
                        @stats.send("f2_t_cbet", player).should be_nil
                    end
                    @stats.t_dbet("sb").should be_false
                    @stats.t_dbet("bb").should be_false
                    @stats.t_dbet("button").should be_nil
                    [:sb, :bb, :button].each do |player|
                        @stats.t_dbet(player).should be_nil
                    end
                    @stats.should have_consistent_street_bet_statistics
                end
            end
            
            context "when button is last aggressor turn and checks on river" do
                before(:each) do
                    register_street :turn
                    register_check(@sb)
                    register_check(@bb)
                    register_bet(@button, 100)
                    register_call(@sb, 100)
                    register_call(@bb, 100)
                    register_street :river
                    register_check(@sb)
                    register_check(@bb)
                    register_check(@button)
                end
                
                it "correctly compute cbet stats" do
                    @stats.r_cbet("sb").should be_nil
                    @stats.r_cbet("bb").should be_nil
                    @stats.r_cbet("button").should be_false
                    ["sb", "bb", "button"].each do |player|
                        @stats.send("c_r_cbet", player).should be_nil
                        @stats.send("f2_r_cbet", player).should be_nil
                    end
                    @stats.r_dbet("sb").should be_false
                    @stats.r_dbet("bb").should be_false
                    @stats.r_dbet("button").should be_nil
                    [:sb, :bb, :button].each do |player|
                        @stats.r_dbet(player).should be_nil
                    end
                    @stats.should have_consistent_street_bet_statistics
                end
            end
        end
    end

    context "when reporting statistics" do
      before(:each) do
        @stats = HandStatistics.new
        @stats.register_player @seat2 = next_sample_player(:seat => 2, :screen_name => "seat2")
        @stats.register_player @seat4 = next_sample_player(:seat => 4, :screen_name => "seat4")
        @stats.register_player @seat6 = next_sample_player(:seat => 6, :screen_name => "seat6")
        @stats.register_player @seat8 = next_sample_player(:seat => 8, :screen_name => "seat8")
        @stats.register_button 1
        @blind_attack_plugin = @stats.plugins.find{|each| each.is_a? BlindAttackStatistics}
        @cash_plugin = @stats.plugins.find{|each| each.is_a? CashStatistics}
        @continuation_bet_plugin = @stats.plugins.find{|each| each.is_a? ContinuationBetStatistics}
        @aggression_plugin = @stats.plugins.find{|each| each.is_a? AggressionStatistics}
        @preflop_raise_plugin = @stats.plugins.find{|each| each.is_a? PreflopRaiseStatistics}
        @street_plugin = @stats.plugins.find{|each| each.is_a? StreetStatistics}
        @street_bet_plugin = @stats.plugins.find{|each| each.is_a? StreetBetStatistics}
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
        report_items = [
            :seat, :position, :cards, :card_category_index, 
            :posted, :paid, :won, :profit, 
            :posted_in_bb, :paid_in_bb, :won_in_bb, :profit_in_bb,
            :starting_stack, :starting_stack_in_bb, :starting_stack_as_M, :starting_stack_as_M_class
        ]
        report_items.each{|report_item| @cash_plugin.should_receive(report_item).exactly(@stats.players.size)}
        @reports = @stats.reports
        report_items.each{|report_item|@stats.players.each{|each| @reports[each].should include(report_item)}}
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

      it "should report street statistics for each player" do
        report_items = [
          :saw_flop,:saw_turn,:saw_river,:saw_showdown, 
          :won_preflop, :won_flop, :won_turn, :won_river, :won_showdown
        ]
        report_items.each{|report_item| @street_plugin.should_receive(report_item).exactly(@stats.players.size)}
        @reports = @stats.reports
        report_items.each{|report_item|@stats.players.each{|each| @reports[each].should include(report_item)}}
      end

      it "should report street bet statistics for each player" do
        report_items = [
            :p_2bet, :p_2bet_o,:p_3bet, :p_3bet_o,:p_4bet, :p_4bet_o, :p_5bet_o,
            :f_1bet, :f_1bet_o,:f_2bet, :f_2bet_o,:f_3bet, :f_3bet_o,:f_4bet, :f_4bet_o, :f_5bet_o,
            :t_1bet, :t_1bet_o,:t_2bet, :t_2bet_o,:t_3bet, :t_3bet_o,:t_4bet, :t_4bet_o, :t_5bet_o,
            :r_1bet, :r_1bet_o,:r_2bet, :r_2bet_o,:r_3bet, :r_3bet_o,:r_4bet, :r_4bet_o, :r_5bet_o,
            :c_f_1bet, :c_f_2bet, :c_f_3bet, :c_f_4bet, 
            :c_t_1bet, :c_t_2bet, :c_t_3bet, :c_t_4bet, 
            :c_r_1bet, :c_r_2bet, :c_r_3bet, :c_r_4bet, 
            :f2_p_1bet, :f2_p_2bet, :f2_p_3bet, :f2_p_4bet, 
            :f2_f_1bet, :f2_f_2bet, :f2_f_3bet, :f2_f_4bet, 
            :f2_t_1bet, :f2_t_2bet, :f2_t_3bet, :f2_t_4bet, 
            :f2_r_1bet, :f2_r_2bet, :f2_r_3bet, :f2_r_4bet,
            :last_aggr_preflop, :last_aggr_flop, :last_aggr_turn, :last_aggr_river,
            :f_cbet, :f_cbet_o,:t_cbet, :t_cbet_o,:r_cbet,
            :c_f_cbet, :c_f_cbet_o,:c_t_cbet, :c_t_cbet_o,:c_r_cbet,
            :f2_f_cbet, :f2_f_cbet_o,:f2_t_cbet, :f2_t_cbet_o,:f2_r_cbet,
            :f_dbet, :f_dbet_o,:t_dbet, :t_dbet_o,:r_dbet,
            :c_f_dbet, :c_f_dbet_o,:c_t_dbet, :c_t_dbet_o,:c_r_dbet,
            :f2_f_dbet, :f2_f_dbet_o,:f2_t_dbet, :f2_t_dbet_o,:f2_r_dbet,:f2_r_dbet_o
        ]
        @reports = @stats.reports
        report_items.each{|report_item|@stats.players.each{|each| @reports[each].should include(report_item)}}
      end
   end
end