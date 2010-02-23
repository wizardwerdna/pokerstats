# coding: utf-8
require 'rubygems'
require 'active_support'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/hand_history')

describe Pokerstats::HandHistory do
    context "when created on an empty string" do
        before(:each) do
            @hand_history = Pokerstats::HandHistory.new([], "", 0)
        end
        
        it {@hand_history.should be_kind_of(Pokerstats::HandHistory)}
        it {@hand_history.should_not be_parsed}
        it "should not find a game" do
            @hand_history.game.should be_nil
        end
    end
    
    context "when created on a hand record" do
        before(:each) do
            lines = <<-HAND_HISTORY
PokerStars Game #24759011305: Tournament #139359808, $10+$1 Hold'em No Limit - Level I (10/20) - 2009/02/09 14:02:39 ET
Table '139359808 122' 9-max Seat #5 is the button
Seat 2: wizardwerdna (3000 in chips) 
Seat 3: EEYORE_Q6 (3000 in chips) 
Seat 4: bimbi76 (3020 in chips) 
Seat 5: izibi (2970 in chips) 
Seat 6: Spidar (2980 in chips) is sitting out
Seat 7: Little Dee (2900 in chips) 
Seat 8: Gwünni (3000 in chips) 
Seat 9: MartinBOF84 (3130 in chips) 
Spidar: posts small blind 10
Little Dee: posts big blind 20
*** HOLE CARDS ***
Dealt to wizardwerdna [Qc 4d]
Gwünni: folds 
MartinBOF84: folds 
wizardwerdna: folds 
EEYORE_Q6: calls 20
bimbi76: folds 
izibi: calls 20
Spidar: folds 
Little Dee: checks ""
*** FLOP *** [Ac Qs Ks]
Little Dee: checks 
EEYORE_Q6: bets 20
izibi: raises 60 to 80
Little Dee: folds 
EEYORE_Q6: calls 60
*** TURN *** [Ac Qs Ks] [Js]
EEYORE_Q6: checks 
izibi: checks 
*** RIVER *** [Ac Qs Ks Js] [8d]
EEYORE_Q6: bets 60
izibi: calls 60
*** SHOW DOWN ***
EEYORE_Q6: shows [2s Ah] (a pair of Aces)
izibi: shows [Ad 6d] (a pair of Aces)
EEYORE_Q6 collected 175 from pot
izibi collected 175 from pot
*** SUMMARY ***
Total pot 350 | Rake 0 
Board [Ac Qs Ks Js 8d]
Seat 2: wizardwerdna folded before Flop (didn't bet)
Seat 3: EEYORE_Q6 showed [2s Ah] and won (175) with a pair of Aces
Seat 4: bimbi76 folded before Flop (didn't bet)
Seat 5: izibi (button) showed [Ad 6d] and won (175) with a pair of Aces
Seat 6: Spidar (small blind) folded before Flop
Seat 7: Little Dee (big blind) folded on the Flop
Seat 8: Gwünni folded before Flop (didn't bet)
Seat 9: MartinBOF84 folded before Flop (didn't bet)
            HAND_HISTORY
            @hand_history = Pokerstats::HandHistory.new(lines.split("\n"),"",0)
        end
        it "should have a game" do
            @hand_history.game.should == "PS24759011305"
        end
        it "should have a parse" do
            @hand_history.parse
            @hand_history.should be_parsed
        end
        it "should have a report" do
            lambda{@hand_history.reports}.should_not raise_error
        end
    end
end