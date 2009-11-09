require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../lib/pokerstats/hand_classification')

include Pokerstats
describe "classIndexFromHandString" do
  it "should recognize pairs" do
    Pokerstats::classIndexFromHandString("AS AH").should == 0
    Pokerstats::classIndexFromHandString("kd kc").should == 14
    Pokerstats::classIndexFromHandString("2H 2D").should == 168
    Pokerstats::classIndexFromHandString("KdkC").should == 14
    Pokerstats::classIndexFromHandString(" Kd kC").should == 14
    Pokerstats::classIndexFromHandString(" Kd  kC ").should == 14
  end
  it "should recognize suited hands" do
    Pokerstats::classIndexFromHandString("AS KS").should == 1
    Pokerstats::classIndexFromHandString("AS 2S").should == 12
    Pokerstats::classIndexFromHandString("3S 2S").should == 155
    Pokerstats::classIndexFromHandString("AS 2s").should == 12
    Pokerstats::classIndexFromHandString("aS 2S").should == 12
    Pokerstats::classIndexFromHandString("As 2s").should == 12
  end
  it "should recognize unsuited hands" do
    Pokerstats::classIndexFromHandString("AS Kh").should == 13
    Pokerstats::classIndexFromHandString("Ad 2c").should == 156
    Pokerstats::classIndexFromHandString("3c 2S").should == 167
    Pokerstats::classIndexFromHandString("AS 2h").should == 156
    Pokerstats::classIndexFromHandString("aS 2d").should == 156
    Pokerstats::classIndexFromHandString("As 2c").should == 156
  end
  it "should not recognize malformed hands" do
    lambda{Pokerstats::classIndexFromHandString("AS AS")}.should raise_error(ArgumentError)
    lambda{Pokerstats::classIndexFromHandString("XS AH")}.should raise_error(ArgumentError)
    lambda{Pokerstats::classIndexFromHandString("AS XH")}.should raise_error(ArgumentError)
    lambda{Pokerstats::classIndexFromHandString("AX AS")}.should raise_error(ArgumentError)
    lambda{Pokerstats::classIndexFromHandString("AX AX")}.should raise_error(ArgumentError)
  end
end
describe "classIndexFromClassString" do
  it "should recognize pairs" do
    Pokerstats::classIndexFromClassString("AA").should == 0
    Pokerstats::classIndexFromClassString("KK").should == 14
    Pokerstats::classIndexFromClassString("22").should == 168
    Pokerstats::classIndexFromClassString("KKp").should == 14
    Pokerstats::classIndexFromClassString("KKP").should == 14
  end
  it "should recognize suited hands" do
    Pokerstats::classIndexFromClassString("AKs").should == 1
    Pokerstats::classIndexFromClassString("A2s").should == 12
    Pokerstats::classIndexFromClassString("32s").should == 155
    Pokerstats::classIndexFromClassString("A2S").should == 12
    Pokerstats::classIndexFromClassString("2As").should == 12
  end
  it "should recognize unsuited hands" do
    Pokerstats::classIndexFromClassString("AKo").should == 13
    Pokerstats::classIndexFromClassString("A2o").should == 156
    Pokerstats::classIndexFromClassString("32o").should == 167
    Pokerstats::classIndexFromClassString("A2O").should == 156
    Pokerstats::classIndexFromClassString("A2").should == 156
    Pokerstats::classIndexFromClassString("2AO").should == 156
  end
end
describe "classStringFromClassIndex" do
  it "should recognize pairs" do
    Pokerstats::classStringFromClassIndex(0).should == "AA"
    Pokerstats::classStringFromClassIndex(14).should == "KK"
    Pokerstats::classStringFromClassIndex(168).should == "22"
  end
  it "should recognize suited hands" do
    Pokerstats::classStringFromClassIndex(1).should == "AKs"
    Pokerstats::classStringFromClassIndex(12).should == "A2s"
    Pokerstats::classStringFromClassIndex(155).should == "32s"
  end
  it "should recognize unsuited hands" do
    Pokerstats::classStringFromClassIndex(13).should == "AKo"
    Pokerstats::classStringFromClassIndex(156).should == "A2o"
    Pokerstats::classStringFromClassIndex(167).should == "32o"
  end
end
describe "rowFromClassIndex" do
  it "should recognize first row indices" do
    Pokerstats::rowFromClassIndex(0).should == 0
    Pokerstats::rowFromClassIndex(7).should == 0
    Pokerstats::rowFromClassIndex(12).should == 0
  end
  it "should recognize middle row indices" do
    Pokerstats::rowFromClassIndex(78).should == 6
    Pokerstats::rowFromClassIndex(88).should == 6
    Pokerstats::rowFromClassIndex(90).should == 6
  end
  it "should recognize last row indices" do
    Pokerstats::rowFromClassIndex(156).should == 12
    Pokerstats::rowFromClassIndex(165).should == 12
    Pokerstats::rowFromClassIndex(168).should == 12
  end
end
describe "colFromClassIndex" do
  it "should recognize first col indices" do
    Pokerstats::colFromClassIndex(0).should == 0
    Pokerstats::colFromClassIndex(78).should == 0
    Pokerstats::colFromClassIndex(156).should == 0

  end
  it "should recognize middle col indices" do
    Pokerstats::colFromClassIndex(7).should == 7
    Pokerstats::colFromClassIndex(85).should == 7
    Pokerstats::colFromClassIndex(163).should == 7

  end
  it "should recognize last col indices" do
    Pokerstats::colFromClassIndex(12).should == 12
    Pokerstats::colFromClassIndex(90).should == 12
    Pokerstats::colFromClassIndex(168).should == 12
  end
end
describe "classIndexFromRowAndCol" do
  it "should recognize top row" do
    Pokerstats::classIndexFromRowAndCol(0,0) == 0
    Pokerstats::classIndexFromRowAndCol(0,7) == 7
    Pokerstats::classIndexFromRowAndCol(0,12) == 12
  end
  it "should recognize middle row pairs" do
    Pokerstats::classIndexFromRowAndCol(7,0) == 84
    Pokerstats::classIndexFromRowAndCol(7,7) == 91
    Pokerstats::classIndexFromRowAndCol(7,12) == 96
  end
  it "should recognize last row pairs" do
    Pokerstats::classIndexFromRowAndCol(12,0) == 156
    Pokerstats::classIndexFromRowAndCol(12,7) == 163
    Pokerstats::classIndexFromRowAndCol(12,12) == 168
  end
end