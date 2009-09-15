require 'rubygems'
require 'activesupport'
require 'bigdecimal'
require 'bigdecimal/util'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/hand_history')
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/hand_statistics')
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/pokerstars_file')
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/pokerstars_hand_history_parser')
include Pokerstats

include HandConstants

describe PokerstarsHandHistoryParser, "when parsing structural matter" do
  before :each do
    @stats = HandStatistics.new
    @parser = PokerstarsHandHistoryParser.new(@stats)
  end
   
  it "should parse a tournament header" do
    @stats.should_receive(:update_hand).with(
      :name => "PS21650436825",
      :description => "117620218, $10+$1 Hold'em No Limit",
      :sb => "10".to_d,
      :bb => "20".to_d,
      :played_at => Time.parse("2008/10/31 17:25:42 ET"),
      :tournament => "117620218",
      :street => :prelude
    )
    @parser.parse("PokerStars Game #21650436825: Tournament #117620218, $10+$1 Hold'em No Limit - Level I (10/20) - 2008/10/31 17:25:42 ET")
    puts @stats.report_hand_information
  end
  
  it "should recognize a tournament header" do
    PokerstarsHandHistoryParser.should have_valid_header("PokerStars Game #21650436825: Tournament #117620218, $10+$1 Hold'em No Limit - Level I (10/20) - 2008/10/31 17:25:42 ET\nsnuggles\n")
  end
  
  it "should parse a cash game header" do
    @stats.should_receive(:update_hand).with(
      :name => 'PS21650146783',
      :description => "Hold'em No Limit ($0.25/$0.50)",
      :sb => "0.25".to_d, 
      :bb => "0.50".to_d,
      :played_at => Time.parse("2008/10/31 17:14:44 ET"),
      :tournament => nil,
      :street => :prelude
    )
    @parser.parse("PokerStars Game #21650146783:  Hold'em No Limit ($0.25/$0.50) - 2008/10/31 17:14:44 ET")
  end
  
  it "should recognize a cash game header" do
    PokerstarsHandHistoryParser.should have_valid_header("PokerStars Game #21650146783:  Hold'em No Limit ($0.25/$0.50) - 2008/10/31 17:14:44 ET\nsnuggles\n")
  end
  
  it "should not recognize an invalid header" do
    PokerstarsHandHistoryParser.should_not have_valid_header("I will love you to the end of the earth\nNow and Forever\nEver Always,\nYour Andrew")
  end
  
  it "should parse a hole card header" do
    @stats.should_receive(:update_hand).with(:street => :preflop)
    @parser.parse("*** HOLE CARDS ***")
  end
  
  it "should parse a flop header" do
    @stats.should_receive(:update_hand).with(:street => :flop)
    @parser.parse("*** FLOP *** [5c 2d Jh]")
  end
  
  it "should parse a turn header" do
    @stats.should_receive(:update_hand).with(:street => :turn)
    @parser.parse("*** TURN *** [5c 2d Jh] [4c]")
  end
  
  it "should parse a river header" do
    @stats.should_receive(:update_hand).with(:street => :river)
    @parser.parse("*** RIVER *** [5c 2d Jh 4c] [5h]")
  end
  
  it "should parse a showdown header" do
    @stats.should_receive(:update_hand).with(:street => :showdown)
    @parser.parse("*** SHOW DOWN *** [5c 2d Jh 4c] [5h]")
  end
  
  it "should parse a summary header" do
    @stats.should_receive(:update_hand).with(:street => :summary)
    @parser.parse("*** SUMMARY *** [5c 2d Jh 4c] [5h]")
  end
  
  it "should parse a 'dealt to' header" do
    @stats.should_receive(:register_action).with('wizardwerdna', 'dealt', :result => :cards, :data => "2s Th")
    @parser.parse("Dealt to wizardwerdna [2s Th]")
  end
  
  it "should parse a 'Total pot' card header" do
    @stats.should_receive(:update_hand).with(:total_pot => "10.75".to_d, :rake => "0.50".to_d)
    @parser.parse("Total pot $10.75 | Rake $0.50")
  end
  
  it "should parse a board header" do
    @stats.should_receive(:update_hand).with(:board => "5c 2d Jh 4c 5h")
    @parser.parse("Board [5c 2d Jh 4c 5h]")
  end
end


describe PokerstarsHandHistoryParser, "when parsing prelude matter" do
  before :each do
    @stats = HandStatistics.new
    @parser = PokerstarsHandHistoryParser.new(@stats)
  end

  it "should parse a tournament button line" do
    @stats.should_receive(:register_button).with(6)
    @parser.parse("Table '117620218 1' 9-max Seat #6 is the button")
  end

  it "should parse a cash game button line" do
    @stats.should_receive(:register_button).with(2)
    @parser.parse("Table 'Charybdis IV' 9-max Seat #2 is the button")
  end

  it "should parse a player line" do
    @stats.should_receive(:register_player).with(:screen_name => 'BadBeat_Brat', :seat => 3)
    @parser.parse("Seat 3: BadBeat_Brat (1500 in chips)")
  end

  it "should parse a player line with accents" do
    @stats.should_receive(:register_player).with(:screen_name => 'Gwünni', :seat => 8)
    @parser.parse("Seat 8: Gwünni (3000 in chips)")
  end

  it "should parse a small blind header and register the corresponding action" do
    @stats.should_receive(:register_action).with("Hoggsnake", 'posts', :result => :post, :amount => "10".to_d)
    @parser.parse("Hoggsnake: posts small blind 10")
  end

  it "should parse a big blind header and register the corresponding action" do
    @stats.should_receive(:register_action).with("BadBeat_Brat", 'posts', :result => :post, :amount => "20".to_d)
    @parser.parse("BadBeat_Brat: posts big blind 20")
  end

  it "should parse an ante header and register the corresponding action" do
    @stats.should_receive(:register_action).with("BadBeat_Brat", 'antes', :result => :post, :amount => "15".to_d)
    @parser.parse("BadBeat_Brat: posts the ante 15")
  end
end

describe PokerstarsHandHistoryParser, "when parsing poker actions" do
  before :each do
    @stats = HandStatistics.new
    @parser = PokerstarsHandHistoryParser.new(@stats)
  end
  
  it "should properly parse and register a fold" do
    @stats.should_receive(:register_action).with("Gwünni", "folds", :result => :neutral)
    @parser.parse("Gwünni: folds")
  end
  it "should properly parse and register a check" do
    @stats.should_receive(:register_action).with("billy", "checks", :result => :neutral)
    @parser.parse("billy: checks")
  end
  it "should properly parse and register a call" do
    @stats.should_receive(:register_action).with("billy", "calls", :result => :pay, :amount => "1.25".to_d)
    @parser.parse("billy: calls $1.25")
  end
  it "should properly parse and register a bet" do
    @stats.should_receive(:register_action).with("billy", "bets", :result => :pay, :amount => "1.20".to_d)
    @parser.parse("billy: bets $1.20")
  end
  it "should properly parse and register a raise" do
    @stats.should_receive(:register_action).with("billy", "raises", :result => :pay_to, :amount => "1.23".to_d)
    @parser.parse("billy: raises $1 to $1.23")
  end
  it "should properly parse and register a return" do
    @stats.should_receive(:register_action).with("billy", "return", :result => :win, :amount => "1.50".to_d)
    @parser.parse("Uncalled bet ($1.50) returned to billy")
  end
  it "should properly parse and register a collection" do
    @stats.should_receive(:register_action).with("billy", "wins", :result => :win, :amount => "1.90".to_d)
    @parser.parse("billy collected $1.90 from pot")
  end
end

