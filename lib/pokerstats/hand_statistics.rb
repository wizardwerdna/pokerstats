require 'rubygems'
require 'pluggable'
require 'bigdecimal'
require 'bigdecimal/util'
require 'activesupport'
require File.expand_path(File.dirname(__FILE__) + '/hand_constants')
require File.expand_path(File.dirname(__FILE__) + '/hand_statistics_api')
module Pokerstats
  class HandStatistics
    include Pluggable
    include HandConstants
    plugin_include_module HandStatisticsAPI
    def initialize
      install_plugins self
      @hand_information = {}
      @player_hashes = []
      @button_player_index = nil
      @cached_player_position = nil
      @street_state = nil
      street_transition(:prelude)
    end

    ##
    # Hand Information
    ##
  
    def hand_record
      raise "#{HAND_RECORD_INCOMPLETE_MESSAGE}: #{(HAND_INFORMATION_KEYS - @hand_information.keys).inspect}" unless (HAND_INFORMATION_KEYS - @hand_information.keys).empty?
      HAND_INFORMATION_KEYS.inject({}) do |hash, key| 
        hash.merge!(key => @hand_information[key])
      end
    end

    def update_hand update
      street_transition(update[:street]) unless update[:street] == @street_state
      @hand_information.update(update)
      self
    end
  
    ##
    # Player Information
    ##
  
    def player_records_without_validation
      @player_hashes
    end

    def player_records
      raise PLAYER_RECORDS_NO_PLAYER_REGISTERED if players.empty?
      raise PLAYER_RECORDS_NO_BUTTON_REGISTERED if button.nil?
      raise PLAYER_RECORDS_OUT_OF_BALANCE if out_of_balance
      self.player_records_without_validation
    end

    def players
      @player_hashes.sort{|a, b| a[:seat] <=> b[:seat]}.collect{|each| each[:screen_name]}
    end
  
    def number_players
      @player_hashes.size
    end
  
    def register_player player
      screen_name = player[:screen_name]
      raise "#{PLAYER_RECORDS_DUPLICATE_PLAYER_NAME}: #{screen_name.inspect}" if players.member?(screen_name)
      @cached_player_position = nil
      @player_hashes << player
      plugins.each{|each| each.register_player(screen_name, @street_state)}  #why the second parameter?
      street_transition_for_player(@street_state, screen_name)
    end
  
    ###
    # Street state information
    ##
  
    def street
      @street_state
    end
  
    def street_transition street
      @street_state = street
      plugins.each{|each| each.street_transition(street)}
      players.each {|player| street_transition_for_player(street, player)}
    end
  
    def street_transition_for_player street, screen_name
      plugins.each{|each| each.street_transition_for_player(street, screen_name)}
    end
  
    ##
    # Button and Position Information
    ##
  
    def register_button button_index
      @cached_player_position = nil
      @button_player_index = button_index
    end
  
    def button
      @button_player_index
    end
  
    def button_relative_seat(player_hash)
      (player_hash[:seat] + MAX_SEATS - @button_player_index) % MAX_SEATS
    end

    # long computation is cached, which cache is cleared every time a new player is registered
    def calculate_player_position screen_name
      @cached_player_position = {}
      @player_hashes.sort!{|a,b| button_relative_seat(a) <=> button_relative_seat(b)}
      @player_hashes = [@player_hashes.pop] + @player_hashes unless @player_hashes.first[:seat] == @button_player_index
      @player_hashes.each_with_index{|player, index| player[:position] = index, @cached_player_position[player[:screen_name]] = index}
      @cached_player_position[screen_name]
    end
  
    def position screen_name
      (@cached_player_position && @cached_player_position[screen_name]) || calculate_player_position(screen_name)
    end
  
    def button?(screen_name)
      position(screen_name) && position(screen_name).zero?
    end
  
    # The cutoff position is defined as the player to the left of the button if there are three players, otherwise nil
    def cutoff_position
      # formerly: (number_players > 3) && (-1 % number_players)
      -1 % number_players if number_players > 3
    end
  
    def cutoff?(screen_name)
      position(screen_name) == cutoff_position
    end
  
    def blind?(screen_name)
      (sbpos?(screen_name) || bbpos?(screen_name)) and !posted(screen_name).zero?
    end
  
    def sbpos?(screen_name)
      (number_players > 2) && position(screen_name) == 1
    end
  
    def bbpos?(screen_name)
      (number_players > 2) && position(screen_name) == 2
    end

    def attacker?(screen_name)
      (number_players > 2) && (button?(screen_name) || cutoff?(screen_name))
    end
  
  
    ##
    # Action Information
    ##
    def aggression(description)
      case description
      when /call/
        :passive
      when /raise/
        :aggressive
      when /bet/
        :aggressive
      when /fold/
        :fold
      when /check/
        :check
      else
        :neutral
      end
    end
  
    def register_action(screen_name, description, options={})
      raise "#{PLAYER_RECORDS_UNREGISTERED_PLAYER}: #{screen_name.inspect}" unless players.member?(screen_name)
      plugins.each do |each|
        each.apply_action(
          {:screen_name => screen_name, :description => description, :aggression => aggression(description)}.update(options), 
          @street_state)
      end
    end
  
    ##
    # Reporting Information
    ##
  
    def report_player(player)
      result = {}
      plugins.each {|each| result.merge!(each.report(player))}
      result
    end
    
    def reports
      result = {}
      players.each{|each| result[each] = report_player(each)}
      result
    end
  
    def report_hand_information
      @hand_information
    end
  
    def self.hand_statistics_migration_data
      HAND_REPORT_SPECIFICATION.inject("") do |string, each|
        string + "t.#{each[1]}\t#{each[0].inspect}\n"
      end
    end
  
    def self.player_statistics_migration_data
      plugin_factory.inject("") do |str, each_plugin|
        tstr = "# from #{each_plugin.inspect}\n"
        each_plugin.report_specification.each do |each_datum|
          tstr += "t.#{each_datum[1]}\t#{each_datum[0].inspect}\n"
        end
        str = str + tstr
      end
    end
    private
    def method_missing symbol, *args
      plugins.send symbol, *args
    end
  end
  Dir[File.dirname(__FILE__) + "/plugins/*_statistics.rb"].each {|filename| require File.expand_path(filename)}
  HandStatistics.delegate_plugin_public_methods_except HandStatisticsAPI.public_methods
end
# Load Plugins and Delegate non-api public methods to plugins
# puts Pokerstats::HandStatistics.hand_statistics_migration_data
# puts Pokerstats::HandStatistics.player_statistics_migration_data
