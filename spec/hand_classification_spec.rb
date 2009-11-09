require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/hand_classification')

include Pokerstats
describe "class_index_from_hand_string" do
  it "should recognize pairs" do
    Pokerstats::class_index_from_hand_string("AS AH").should == 0
    Pokerstats::class_index_from_hand_string("kd kc").should == 14
    Pokerstats::class_index_from_hand_string("2H 2D").should == 168
    Pokerstats::class_index_from_hand_string("KdkC").should == 14
    Pokerstats::class_index_from_hand_string(" Kd kC").should == 14
    Pokerstats::class_index_from_hand_string(" Kd  kC ").should == 14
  end
  it "should recognize suited hands" do
    Pokerstats::class_index_from_hand_string("AS KS").should == 1
    Pokerstats::class_index_from_hand_string("AS 2S").should == 12
    Pokerstats::class_index_from_hand_string("3S 2S").should == 155
    Pokerstats::class_index_from_hand_string("AS 2s").should == 12
    Pokerstats::class_index_from_hand_string("aS 2S").should == 12
    Pokerstats::class_index_from_hand_string("As 2s").should == 12
  end
  it "should recognize unsuited hands" do
    Pokerstats::class_index_from_hand_string("AS Kh").should == 13
    Pokerstats::class_index_from_hand_string("Ad 2c").should == 156
    Pokerstats::class_index_from_hand_string("3c 2S").should == 167
    Pokerstats::class_index_from_hand_string("AS 2h").should == 156
    Pokerstats::class_index_from_hand_string("aS 2d").should == 156
    Pokerstats::class_index_from_hand_string("As 2c").should == 156
  end
  it "should not recognize malformed hands" do
    Pokerstats::class_index_from_hand_string("AS AS").should be_nil
    Pokerstats::class_index_from_hand_string("XS AH").should be_nil
    Pokerstats::class_index_from_hand_string("AS XH").should be_nil
    Pokerstats::class_index_from_hand_string("AX AS").should be_nil
    Pokerstats::class_index_from_hand_string("AX AX").should be_nil
    lambda{Pokerstats::class_index_from_hand_string!("AS AS")}.should raise_error(ArgumentError)
    lambda{Pokerstats::class_index_from_hand_string!("XS AH")}.should raise_error(ArgumentError)
    lambda{Pokerstats::class_index_from_hand_string!("AS XH")}.should raise_error(ArgumentError)
    lambda{Pokerstats::class_index_from_hand_string!("AX AS")}.should raise_error(ArgumentError)
    lambda{Pokerstats::class_index_from_hand_string!("AX AX")}.should raise_error(ArgumentError)
  end
end
describe "class_index_from_class_string" do
  it "should recognize pairs" do
    Pokerstats::class_index_from_class_string("AA").should == 0
    Pokerstats::class_index_from_class_string("KK").should == 14
    Pokerstats::class_index_from_class_string("22").should == 168
    Pokerstats::class_index_from_class_string("KKp").should == 14
    Pokerstats::class_index_from_class_string("KKP").should == 14
  end
  it "should recognize suited hands" do
    Pokerstats::class_index_from_class_string("AKs").should == 1
    Pokerstats::class_index_from_class_string("A2s").should == 12
    Pokerstats::class_index_from_class_string("32s").should == 155
    Pokerstats::class_index_from_class_string("A2S").should == 12
    Pokerstats::class_index_from_class_string("2As").should == 12
  end
  it "should recognize unsuited hands" do
    Pokerstats::class_index_from_class_string("AKo").should == 13
    Pokerstats::class_index_from_class_string("A2o").should == 156
    Pokerstats::class_index_from_class_string("32o").should == 167
    Pokerstats::class_index_from_class_string("A2O").should == 156
    Pokerstats::class_index_from_class_string("A2").should == 156
    Pokerstats::class_index_from_class_string("2AO").should == 156
  end
end
describe "class_string_from_class_index" do
  it "should recognize pairs" do
    Pokerstats::class_string_from_class_index(0).should == "AA"
    Pokerstats::class_string_from_class_index(14).should == "KK"
    Pokerstats::class_string_from_class_index(168).should == "22"
  end
  it "should recognize suited hands" do
    Pokerstats::class_string_from_class_index(1).should == "AKs"
    Pokerstats::class_string_from_class_index(12).should == "A2s"
    Pokerstats::class_string_from_class_index(155).should == "32s"
  end
  it "should recognize unsuited hands" do
    Pokerstats::class_string_from_class_index(13).should == "AKo"
    Pokerstats::class_string_from_class_index(156).should == "A2o"
    Pokerstats::class_string_from_class_index(167).should == "32o"
  end
end
describe "row_from_class_index" do
  it "should recognize first row indices" do
    Pokerstats::row_from_class_index(0).should == 0
    Pokerstats::row_from_class_index(7).should == 0
    Pokerstats::row_from_class_index(12).should == 0
  end
  it "should recognize middle row indices" do
    Pokerstats::row_from_class_index(78).should == 6
    Pokerstats::row_from_class_index(88).should == 6
    Pokerstats::row_from_class_index(90).should == 6
  end
  it "should recognize last row indices" do
    Pokerstats::row_from_class_index(156).should == 12
    Pokerstats::row_from_class_index(165).should == 12
    Pokerstats::row_from_class_index(168).should == 12
  end
end
describe "col_from_class_index" do
  it "should recognize first col indices" do
    Pokerstats::col_from_class_index(0).should == 0
    Pokerstats::col_from_class_index(78).should == 0
    Pokerstats::col_from_class_index(156).should == 0

  end
  it "should recognize middle col indices" do
    Pokerstats::col_from_class_index(7).should == 7
    Pokerstats::col_from_class_index(85).should == 7
    Pokerstats::col_from_class_index(163).should == 7

  end
  it "should recognize last col indices" do
    Pokerstats::col_from_class_index(12).should == 12
    Pokerstats::col_from_class_index(90).should == 12
    Pokerstats::col_from_class_index(168).should == 12
  end
end
describe "class_index_from_row_and_col" do
  it "should recognize top row" do
    Pokerstats::class_index_from_row_and_col(0,0) == 0
    Pokerstats::class_index_from_row_and_col(0,7) == 7
    Pokerstats::class_index_from_row_and_col(0,12) == 12
  end
  it "should recognize middle row pairs" do
    Pokerstats::class_index_from_row_and_col(7,0) == 84
    Pokerstats::class_index_from_row_and_col(7,7) == 91
    Pokerstats::class_index_from_row_and_col(7,12) == 96
  end
  it "should recognize last row pairs" do
    Pokerstats::class_index_from_row_and_col(12,0) == 156
    Pokerstats::class_index_from_row_and_col(12,7) == 163
    Pokerstats::class_index_from_row_and_col(12,12) == 168
  end
end