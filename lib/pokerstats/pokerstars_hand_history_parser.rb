require File.expand_path(File.dirname(__FILE__) + '/hand_constants')
require File.expand_path(File.dirname(__FILE__) + '/hand_statistics')

module Pokerstats
  CASH = "[0-9$,.]+"

  class HandHistoryParseError < RuntimeError 
  end
  class PokerstarsHandHistoryParser
    def self.parse_lines(lines, stats=nil)
      parser = self.new(stats)
      lines.each {|line| parser.parse(line)}
    end
    
    def self.has_valid_header?(lines)
      !game(lines).nil?
    end
    
    def self.game(lines)
      lines.lstrip!
      case lines.first.chomp
      when /PokerStars Game #([0-9]+): Tournament #([0-9]+), (\$[0-9+$]+) ([^\-]*) - Level ([IVXL]+) \((#{CASH})\/(#{CASH})\) - (.*)$/
        "PS#{$1}"
      when /PokerStars Game #([0-9]+): +([^(]*) \((#{CASH})\/(#{CASH})\) - (.*)$/
        "PS#{$1}"
      when /PokerStars Game #([0-9]+): +([^(]*) \((#{CASH})\/(#{CASH}) USD\) - (.*)$/
        "PS#{$1}"
      else
        nil
      end
    end
  
    def initialize stats=nil
      @stats = stats || HandStatistics.new
    end
    
    def ignorable?(line)
      regular_expressions_for_ignorable_phrases = [
        /(.*): doesn't show hand/,
        /(.*) has timed out/,
        /(.*) has returned/,
        /(.*) leaves the table/,
        /(.*) joins the table at seat #[0-9]+/,
        /(.*) sits out/,
        /(.*) mucks hand/,
        /(.*) is sitting out/,    
        /(.*) is (dis)?connected/,
        /(.*) said,/, 
        /(.*) will be allowed to play after the button/,
        /(.*) was removed from the table for failing to post/,
        /(.*) re-buys and receives (.*) chips for (.*)/,
        /Seat [0-9]+: (.*) \(((small)|(big)) blind\) folded on the Flop/,
        /Seat [0-9]+: (.*) folded on the ((Flop)|(Turn)|(River))/,
        /Seat [0-9]+: (.*) folded before Flop \(didn't bet\)/,
        /Seat [0-9]+: (.*) (\((small blind)|(big blind)|(button)\) )?folded before Flop( \(didn't bet\))?/,
        /Seat [0-9]+: (.*) (\((small blind)|(big blind)|(button)\) )?collected (.*)/,
        /^\s*$/    
      ]
      regular_expressions_for_ignorable_phrases.any?{|re| re =~ line }
    end
  
    def parse(line)
      case line
      when /PokerStars Game #([0-9]+): Tournament #([0-9]+), (\$[0-9+$]+) ([^\-]*) - Level ([IVXL]+) \((#{CASH})\/(#{CASH})\) - (.*)$/
        @stats.update_hand :name => "PS#{$1}", :description=> "#{$2}, #{$3} #{$4}", :tournament=> $2, :sb=> $6.to_d, :bb=> $7.to_d, :played_at=> Time.parse($8), :street => :prelude, :board => ""
      when /PokerStars Game #([0-9]+): +([^(]*) \((#{CASH})\/(#{CASH})\) - (.*)$/
        @stats.update_hand :name => "PS#{$1}", :description=> "#{$2} (#{$3}/#{$4})", :tournament=> nil, :sb=> cash_to_d($3), :bb=> cash_to_d($4), :played_at=> Time.parse($5), :street => :prelude, :board => ""
      when /PokerStars Game #([0-9]+): +([^(]*) \((#{CASH})\/(#{CASH}) USD\) - (.*)$/
        @stats.update_hand :name => "PS#{$1}", :description=> "#{$2} (#{$3}/#{$4})", :tournament=> nil, :sb=> cash_to_d($3), :bb=> cash_to_d($4), :played_at=> Time.parse($5), :street => :prelude, :board => ""
      when /PokerStars Game #([0-9]+):/
        raise HandHistoryParseError, "invalid hand record: #{line}"
      when /\*\*\* HOLE CARDS \*\*\*/
        @stats.register_button(@stats.button)
        @stats.update_hand :street => :preflop
      when /\*\*\* FLOP \*\*\* \[(.*)\]/
        @stats.update_hand :street => :flop
      when /\*\*\* TURN \*\*\* \[([^\]]*)\] \[([^\]]*)\]/
        @stats.update_hand :street => :turn
      when /\*\*\* RIVER \*\*\* \[([^\]]*)\] \[([^\]]*)\]/
        @stats.update_hand :street => :river
      when /\*\*\* SHOW DOWN \*\*\*/
        @stats.update_hand :street => :showdown
      when /\*\*\* SUMMARY \*\*\*/
        @stats.update_hand :street => :summary
      when /Dealt to ([^)]+) \[([^\]]+)\]/
        @stats.register_action($1, 'dealt', :result => :cards, :data => $2)
      when /(.*): shows \[(.*)\]/
        @stats.register_action($1, 'shows', :result => :cards, :data => $2)
      when /Board \[(.*)\]/
        @stats.update_hand :board => $1
      when /Total pot (#{CASH}) (((Main)|(Side)) pot(-[0-9]+)? (#{CASH}). )*\| Rake (#{CASH})/
        @stats.update_hand(:total_pot => cash_to_d($1), :rake => cash_to_d($8))
      when /Total pot (#{CASH}) Main pot (#{CASH}).( Side pot-[0-9]+ (#{CASH}).)* | Rake (#{CASH})/
        raise HandHistoryParseError, "popo!"
      when /Seat ([0-9]+): (.+) \(#{CASH} in chips\)( is sitting out)?/
        @stats.register_player(:seat => $1.to_i, :screen_name => $2)
      when /(.*): posts ((small)|(big)|(small \& big)) blind(s)? (#{CASH})/
        @stats.register_action($1, 'posts', :result => :post, :amount => cash_to_d($7))
      when /(.*): posts the ante (#{CASH})/
        @stats.register_action($1, 'antes', :result => :post, :amount => cash_to_d($2))
      when /Table '([0-9]+) ([0-9]+)' (.*) Seat #([0-9]+) is the button/
        @stats.register_button($4.to_i)
      when /Table '(.*)' (.*) Seat #([0-9]+) is the button/
        @stats.register_button($3.to_i)
      when /Uncalled bet \((.*)\) returned to (.*)/
        @stats.register_action($2, 'return', :result => :win, :amount => cash_to_d($1))
      when /(.+): ((folds)|(checks))/
        @stats.register_action($1, $2, :result => :neutral)
      when /(.+): ((calls)|(bets)) ((#{CASH})( and is all-in)?)?$/
        @stats.register_action($1, $2, :result => :pay, :amount => cash_to_d($6))
      when /(.+): raises (#{CASH}) to (#{CASH})( and is all-in)?$/      
        @stats.register_action($1, 'raises', :result => :pay_to, :amount => cash_to_d($3))
      when /(.*) collected (.*) from ((side )|(main ))?pot/
        @stats.register_action($1, "wins", :result => :win, :amount => cash_to_d($2))
      when /Seat [0-9]+: (.*) (\((small blind)|(big blind)|(button)\) )?showed \[([^\]]+)\] and ((won) \(#{CASH}\)|(lost)) with (.*)/
      when /Seat [0-9]+: (.*) mucked \[([^\]]+)\]/
      else
        raise HandHistoryParseError, "invalid line for parse: #{line}" unless ignorable?(line)
      end
    end
  
    private
  
    def cash_to_d(string)
      string.gsub!(/[$, ]/,"")
      string.to_d
    end
  end
end