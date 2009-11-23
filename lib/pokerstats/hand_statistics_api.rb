module Pokerstats
  module HandStatisticsAPI
    def initialize handstatistics
      @hand_statistics = handstatistics
    end

    def self.exposed_methods
      self.public_instance_methods - StatisticsHolder.public_instance_methods
    end

    def report screen_name
      automatic_report screen_name
    end

    def register_player screen_name, street, player_hash
    end

    def street_transition street
    end

    def street_transition_for_player street, player
    end

    def apply_action action, street
    end
  
    def automatic_report screen_name
      result = {}
      self.class.report_specification.each do |each|
        result[each[0]] = send(each[2], screen_name)
      end
      result
    end
    
    private
  
    module ClassMethods
      def report_specification
        [
          # [key,   sql_type,   function]
        ]
      end
  
      def rails_migration_segment_for_player_data
        prefix = "\n" + " " * 10
        result = "#{prefix}# FROM #{self.to_s}"
        report_specification.each do |each|
          result += "#{prefix}t.#{each[1]}\t#{each[0].inspect}"
        end
        result += "\n"
      end
    
      def rails_generator_command_line_for_player_data
        report_specification.inject("") do |string, each|
          string + "#{each[0]}:#{each[1]} " 
        end
      end
    end
    
    def self.included(klass)
      klass.extend ClassMethods
    end
  end
end