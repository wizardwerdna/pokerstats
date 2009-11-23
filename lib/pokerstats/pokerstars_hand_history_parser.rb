require File.expand_path(File.dirname(__FILE__) + '/hand_constants')
require File.expand_path(File.dirname(__FILE__) + '/hand_statistics')
require 'tzinfo'

module Pokerstats
  CASH = "[0-9$,.]+"
  
  class PokerstarsTimeStringConverter
      attr_accessor :timestring
      
      def initialize(timestring)
          @timestring = timestring
          parse_timestring
          self
      end

      def as_utc_datetime
          time_converter.local_to_utc(DateTime.parse(@timestring))
      end

      private
      
      def parse_timestring
          if @timestring =~ /^(.*)(UTC|PT|MT|CT|ET|AT|BRT|WET|CET|EET|MSK|CCT|JST|AWST|ACST|AEST|NZT)$/
              @localtime = $1
              @ps_timezone_string = $2
          else
              raise ArgumentError, "time string does not end with a valid Pokerstars time zone suffix"
          end
      end
      
      def time_converter
          case @ps_timezone_string
              when "ACST" then	 TZInfo::Timezone.get('Australia/Adelaide')
              when "AEST" then	 TZInfo::Timezone.get('Australia/Melbourne')
              when "AT" then	 TZInfo::Timezone.get('Canada/Atlantic')
              when "AWST" then	 TZInfo::Timezone.get('Australia/West')
              when "BRT" then	 TZInfo::Timezone.get('Brazil/East')
              when "CCT" then	 TZInfo::Timezone.get('Indian/Cocos')
              when "CET" then	 TZInfo::Timezone.get('Europe/Amsterdam')
              when "CT" then	 TZInfo::Timezone.get('US/Central')
              when "ET" then	 TZInfo::Timezone.get('US/Eastern')
              when "EET" then	 TZInfo::Timezone.get('EET')
              when "JST" then	 TZInfo::Timezone.get('Japan')
              when "MSK" then	 TZInfo::Timezone.get('Europe/Moscow')
              when "MT" then	 TZInfo::Timezone.get('US/Mountain')
              when "NZT" then	 TZInfo::Timezone.get('NZ')
              when "PT" then	 TZInfo::Timezone.get('US/Pacific')
              when "UTC" then	 TZInfo::Timezone.get('UTC')
              when "WET" then	 TZInfo::Timezone.get('WET')
          end
      end
  end
  
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
      return nil if lines.empty?
      case lines[/[^\n]+/].chomp
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
        /(.*) has timed out/,
        /(.*) has returned/,
        /(.*) leaves the table/,
        /(.*) joins the table at seat #[0-9]+/,
        /(.*) sits out/,
        /(.*) is sitting out/,    
        /(.*) is (dis)?connected/,
        /(.*) said,/, 
        /(.*): doesn't show hand/,        
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
      when /PokerStars Game #([0-9]+): Tournament #([0-9]+), (#{CASH})\+(#{CASH}) Hold'em (Pot |No |)Limit - Level ([IVXL]+) \((#{CASH})\/(#{CASH})\) - (.*)$/
        @stats.update_hand :name => "PS#{$1}", :description=> "#{$2}, #{$3}+#{$4} Hold'em #{$5}Limit", :tournament=> $2, 
            :sb=> $7.to_d, :bb=> $8.to_d, :ante => "0.0".to_d, 
            :played_at=> PokerstarsTimeStringConverter.new($9).as_utc_datetime,
            :street => :prelude, :board => "", :max_players => 0, :number_players => 0, :table_name => "",
            :game_type => "Hold'em", :limit_type => "#{$5}Limit", :stakes_type => cash_to_d($3)
      when /PokerStars Game #([0-9]+): Tournament #([0-9]+), (Freeroll|(#{CASH})\+(#{CASH}) *(USD)?) +Hold'em (Pot |No |)Limit -.*Level ([IVXL]+) \((#{CASH})\/(#{CASH})\) - (.*)$/
        @stats.update_hand :name => "PS#{$1}", :description=> "#{$2}, #{$3} Hold'em #{$7}Limit", :tournament=> $2, 
            :sb=> $9.to_d, :bb=> $10.to_d, :ante => "0.0".to_d, 
            :played_at=> PokerstarsTimeStringConverter.new($11).as_utc_datetime,
            :street => :prelude, :board => "", :max_players => 0, :number_players => 0, :table_name => "",
            :game_type => "Hold'em", :limit_type => "#{$7}Limit", :stakes_type => cash_to_d($4)            
      when /PokerStars Game #([0-9]+): Tournament #([0-9]+), (Freeroll|(#{CASH}).*(FPP)) *(USD)? +Hold'em (Pot |No |)Limit -.*Level ([IVXL]+) \((#{CASH})\/(#{CASH})\) - (.*)$/
        @stats.update_hand :name => "PS#{$1}", :description=> "#{$2}, #{$3} Hold'em #{$7}Limit", :tournament=> $2, 
            :sb=> $9.to_d, :bb=> $10.to_d, :ante => "0.0".to_d, 
            :played_at=> PokerstarsTimeStringConverter.new($11).as_utc_datetime,
            :street => :prelude, :board => "", :max_players => 0, :number_players => 0, :table_name => "",
            :game_type => "Hold'em", :limit_type => "#{$7}Limit", :stakes_type => "0".to_d
      when /PokerStars Game #([0-9]+): +([^(]*)Hold'em (No |Pot |)Limit \((#{CASH})\/(#{CASH})\) - (.*)$/
        @stats.update_hand :name => "PS#{$1}", :description=> "#{$2}Hold'em #{$3}Limit (#{$4}/#{$5})", :tournament=> nil, 
            :sb=> cash_to_d($4), :bb=> cash_to_d($5), :ante => "0.0".to_d, 
            :played_at=> PokerstarsTimeStringConverter.new($6).as_utc_datetime,
            :street => :prelude, :board => "", :max_players => 0, :number_players => 0, :table_name => "",
            :game_type => "Hold'em", :limit_type => "#{$3}Limit", :stakes_type => cash_to_d($5)
      when /PokerStars Game #([0-9]+): +([^(]*)Hold'em (No |Pot |)Limit \((#{CASH})\/(#{CASH}) USD\) - (.*)$/
        @stats.update_hand :name => "PS#{$1}", :description=> "#{$2}Hold'em #{$3}LImit (#{$4}/#{$5})", :tournament=> nil, 
            :sb=> cash_to_d($4), :bb=> cash_to_d($5), :ante => "0.0".to_d, 
            :played_at=> PokerstarsTimeStringConverter.new($6).as_utc_datetime,
            :street => :prelude, :board => "", :max_players => 0, :number_players => 0, :table_name => "",
            :game_type => "Hold'em", :limit_type => "#{$3}Limit", :stakes_type => cash_to_d($5)
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
      when /Seat ([0-9]+): (.+) \((#{CASH}) in chips\)( is sitting out)?/
        @stats.register_player(:seat => $1.to_i, :screen_name => $2, :starting_stack => cash_to_d($3))
      when /(.*): posts ((small)|(big)|(small \& big)) blind(s)? (#{CASH})/
        @stats.register_action($1, 'posts', :result => :post, :amount => cash_to_d($7))
      when /(.*): posts the ante (#{CASH})/
        @stats.register_action($1, 'antes', :result => :post, :amount => cash_to_d($2))
        @stats.update_hand(:ante => [cash_to_d($2), @stats.hand_information(:ante)].max)
      # when /Table '([0-9]+) ([0-9]+)' ([0-9]+)-max Seat #([0-9]+) is the button/
      #   @stats.register_button($4.to_i)
      when /Table '(.*)' ([0-9]+)-max Seat #([0-9]+) is the button/
        @stats.register_button($3.to_i)
        @stats.update_hand(:table_name => $1, :max_players => $2.to_i)
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
      when /(.*): mucks hand/
        @stats.register_action($1, 'mucks', :result => :neutral)
      when /Seat [0-9]+: (.*) (\((small blind)|(big blind)|(button)\) )?showed \[([^\]]+)\] and ((won) \(#{CASH}\)|(lost)) with (.*)/
      when /Seat [0-9]+: (.*) mucked \[([^\]]+)\]/
      else
        raise HandHistoryParseError, "invalid line for parse: #{line}" unless ignorable?(line)
      end
    end
  
    private
  
    def cash_to_d(string)
      return "0".to_d if string.nil? || string.empty?
      string.gsub!(/[$, ]/,"")
      string.to_d
    end
  end
end