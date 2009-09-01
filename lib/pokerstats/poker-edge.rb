require 'rubygems'
require 'hpricot'
require 'open-uri'

module Pokerstats
  class PokerEdge
  
    def initialize screen_name
      @screen_name = URI.escape(screen_name)
    end
  
    def get_response_from_internet
      url = "http://www.poker-edge.com/whoami.php?name=#{@screen_name}"
      puts url
      open(url) do |f|
        @response = f.read
      end
      @response
    end
  
    def response
      @response ||= get_response_from_internet
    end
  
    def preflop_style
      if self.response =~ /(Pre-Flop Tend.*\n)/
        verbose = $1.gsub(/<\/?[^>]*>/, "")
        if verbose =~ /Pre-Flop Tendency: ([^-]*) -/
          preflop_style = $1
        else
          preflop_style = "N/A"
        end
      end
      preflop_style
    end
  
    def player_type
      if response =~ /(Player Type.*\n)/
        verbose = $1.gsub(/<\/?[^>]*>/, "")
        if verbose =~ /[Yy]ou are a ([^(]* \(.*\))/
          player = $1
        else
          player = ""
        end
      end
      player
    end
  
    def report format = "%20s -- %s -- %s\n"
      open("foo.html", "w+") do |file|
        file.write(response)
      end
      `open foo.html`
      printf(format, @screen_name, preflop_style, player_type)
    end
  end
end