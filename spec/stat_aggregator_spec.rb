require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/stat_aggregator')

describe Pokerstats::StatAggregator do

  STAT_SPECIFICATION_HASH = {
    :t_data_items => lambda{|hash| 1},
    :t_zero_numeric_items => lambda{|hash| hash[:numeric_item].nil? ? nil : hash[:numeric_item].zero?},
    :t_numeric_item => :numeric_item,
    :t_boolean_item => :is_boolean_item
  }

  DATA_ITEM_WITH_ZERO_NUMERIC_AND_TRUE_BOOLEAN      = {:numeric_item => 0,    :is_boolean_item => true}
  DATA_ITEM_WITH_NON_ZERO_NUMERIC_AND_FALSE_BOOLEAN = {:numeric_item => 2,    :is_boolean_item => false}
  DATA_ITEM_WITH_NIL_NUMERIC_AND_TRUE_BOOLEAN       = {:numeric_item => nil,  :is_boolean_item => true}
  ALL_DATA_ITEMS = [
    DATA_ITEM_WITH_ZERO_NUMERIC_AND_TRUE_BOOLEAN,
    DATA_ITEM_WITH_NON_ZERO_NUMERIC_AND_FALSE_BOOLEAN,
    DATA_ITEM_WITH_NIL_NUMERIC_AND_TRUE_BOOLEAN
  ]
  
  before(:each) do
    @stat_aggregator = Pokerstats::StatAggregator.new(STAT_SPECIFICATION_HASH)
  end
  
  context "when created" do
    it "generates data with the correct initial values" do
      data = @stat_aggregator.data
      STAT_SPECIFICATION_HASH.each do |key, value|
        data[key].items.should be_zero
        data[key].total.should be_zero
      end
    end
  end

  context "after applying a non-null zero numeric and boolean true result" do
    before(:each) do
      EXPECTED_AGGREGATION_REPORT_FOR_ZERO_NUMERIC_AND_TRUE_BOOLEAN = {
        :t_data_items         => Pokerstats::StatAggregationCount.new(1, 1),
        :t_zero_numeric_items => Pokerstats::StatAggregationCount.new(1, 1),
        :t_numeric_item       => Pokerstats::StatAggregationCount.new(1, 0),
        :t_boolean_item       => Pokerstats::StatAggregationCount.new(1, 1)    
      }
      @applied = @stat_aggregator.apply DATA_ITEM_WITH_ZERO_NUMERIC_AND_TRUE_BOOLEAN
    end
    it "generates data with the correct applied values with a numeric and a boolean true result" do
      @stat_aggregator.data.should == EXPECTED_AGGREGATION_REPORT_FOR_ZERO_NUMERIC_AND_TRUE_BOOLEAN
    end
  end
  
  context "after applying a non-null non-zero numeric and boolean false result" do
    before(:each) do
      EXPECTED_AGGREGATION_REPORT_FOR_NON_ZERO_NUMERIC_AND_FALSE_BOOLEAN = {
        :t_data_items         => Pokerstats::StatAggregationCount.new(1, 1),
        :t_zero_numeric_items => Pokerstats::StatAggregationCount.new(1, 0),
        :t_numeric_item       => Pokerstats::StatAggregationCount.new(1, 2),
        :t_boolean_item       => Pokerstats::StatAggregationCount.new(1, 0)    
      }
      @applied = @stat_aggregator.apply DATA_ITEM_WITH_NON_ZERO_NUMERIC_AND_FALSE_BOOLEAN
    end
    it "generates data with the correct applied values with a numeric and a boolean true result" do
      @stat_aggregator.data.should == EXPECTED_AGGREGATION_REPORT_FOR_NON_ZERO_NUMERIC_AND_FALSE_BOOLEAN
    end
  end
  
  context "after applying a non-null non-zero numeric and boolean false result" do
    before(:each) do
      EXPECTED_AGGREGATION_REPORT_FOR_NIL_NUMERIC_AND_TRUE_BOOLEAN = {
        :t_data_items         => Pokerstats::StatAggregationCount.new(1, 1),
        :t_zero_numeric_items => Pokerstats::StatAggregationCount.new(0, 0),
        :t_numeric_item       => Pokerstats::StatAggregationCount.new(0, 0),
        :t_boolean_item       => Pokerstats::StatAggregationCount.new(1, 1)    
      }
      @applied = @stat_aggregator.apply DATA_ITEM_WITH_NIL_NUMERIC_AND_TRUE_BOOLEAN
    end
    it "generates data with the correct applied values with a numeric and a boolean true result" do
      @stat_aggregator.data.should == EXPECTED_AGGREGATION_REPORT_FOR_NIL_NUMERIC_AND_TRUE_BOOLEAN
    end
  end
  
  context "after applying the full set of data" do
    before(:each) do
      EXPECTED_AGGREGATION_REPORT = {
        :t_data_items         => Pokerstats::StatAggregationCount.new(3, 3),
        :t_zero_numeric_items => Pokerstats::StatAggregationCount.new(2, 1),
        :t_numeric_item       => Pokerstats::StatAggregationCount.new(2, 2),
        :t_boolean_item       => Pokerstats::StatAggregationCount.new(3, 2)
      }
      ALL_DATA_ITEMS.each{|item| @stat_aggregator.apply item}
    end
    it "generates data with the correct applied values with a numeric and a boolean true result" do
      puts ALL_DATA_ITEMS.to_yaml
      puts EXPECTED_AGGREGATION_REPORT.to_yaml
      puts @stat_aggregator.data.to_yaml
      @stat_aggregator.data.should == EXPECTED_AGGREGATION_REPORT
    end
  end
end

# @aggreation_specification_hash = {
#   :t_hands => {|hash| 1}
#   :t_vpip => {|hash| hash[:paid].zero?}
#   :t_posted => :posted
#   :t_posted, :posted
#   :t_paid, :paid
#   :t_won, :won
#   :t_preflop_passive, :preflop_passive
#   :t_preflop_aggressive, :preflop_aggressive
#   :t_postflop_passive, :postflop_passive
#   :t_postflop_aggressive, :postflop_aggressive
#   :t_blind_attack_opportunity, :is_blind_attack_opportunity
#   :t_blind_attack_opportunity_taken, :is_blind_attack_opportunity_taken
#   :t_blind_defense_opportunity, :is_blind_defense_opportunity
#   :t_blind_defense_opportunity_taken, :is_blind_defense_opportunity_taken
#   :t_pfr_opportunity, :is_pfr_opportunity
#   :t_pfr_opportunity_taken, :is_pfr_opportunity_taken
#   :t_cbet_opportunity, :is_cbet_opportunity
#   :t_cbet_opportunity_taken, :is_cbet_opportunity_taken
# }