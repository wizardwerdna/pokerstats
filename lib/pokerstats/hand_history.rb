require File.expand_path(File.dirname(__FILE__) + "/hand_constants")
require File.expand_path(File.dirname(__FILE__) + "/pokerstars_hand_history_parser")

module Pokerstats
  class HandHistory
    attr_accessor :lines, :source, :position, :stats
    
    def initialize lines, source, position, parser_class = PokerstarsHandHistoryParser
      @lines = lines
      @source = source
      @position = position
      @parsed = false
      @parser_class = parser_class
      @stats = HandStatistics.new
    end
    
    def game
      @parser_class.game [/[^[\n]+/]
    end
  
    def parsed?
      @parsed
    end
  
    def parse
      @parser = @parser_class.new(@stats)
      @lines.each do |each_line| 
        begin
          @parser.parse(each_line)
        rescue => e
          raise "#{@source}:#{position}: #{e.message}"
        end
      end
      @stats.update_hand :session_filename => source, :starting_at => position
      @parsed = true
    end
  
    def reports
      parse unless parsed?
      @stats.reports
    end
  end
end