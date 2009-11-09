require File.expand_path(File.dirname(__FILE__) + "/hand_constants")
module Pokerstats
  
  def classIndexFromHandString(handString)
    classIndexFromClassString(classStringFromHandString(handString))
  end
  
  def classStringFromHandString(handString)
    raise ArgumentError, "handString must be a String" unless handString.kind_of?(String)
    handString = handString.gsub(/ /,'')
    handString = handString.upcase
    raise ArgumentError, "handString must have 4 non-blank characters" unless handString.size==4
    firstRank, firstSuit, secondRank, secondSuit = *handString.split('')
    raise ArgumentError, "handString suit characters must be from CDHS" unless "CDHS".include?(firstSuit) && "CDHS".include?(secondSuit)
    firstRankIndex, secondRankIndex = Pokerstats::HandConstants::CARDS.index(firstRank), Pokerstats::HandConstants::CARDS.index(secondRank) 
    raise ArgumentError, "handString rank characters must be from AKQJT98765432" if firstRankIndex.nil? || secondRankIndex.nil?
    if firstRank==secondRank
      raise ArgumentError, "handString cards must be different" if firstSuit == secondSuit || !"CDHS".include?(firstSuit)
      firstRank*2
    else
      if firstRankIndex > secondRankIndex
        result = firstRank + secondRank
      else
        result = secondRank + firstRank
      end
      if firstSuit == secondSuit
        result += "s"
      end
      result
    end
  end
  
  def classIndexFromClassString(classString)
    raise ArgumentError, "classString #{classString.inspect} must be a String" unless classString.kind_of?(String)
    classString.upcase!
    first = Pokerstats::HandConstants::CARDS.index(classString[0..0])
    second = Pokerstats::HandConstants::CARDS.index(classString[1..1])
    first, second = second, first if first > second
    raise ArgumentError, "classString is malformed" if first.nil? || second.nil?
    case classString[2..2]
    when "S","P"
      13*first+second
    when "O",""
      13*second+first      
    else raise ArgumentError, "classString is malformed"
    end
  end
  
  def classStringFromClassIndex(classIndex)
    row, col = rowFromClassIndex(classIndex), colFromClassIndex(classIndex)
    case row <=> col
    when 1
      Pokerstats::HandConstants::CARDS[col..col] + Pokerstats::HandConstants::CARDS[row..row] + "o"
    when 0
      Pokerstats::HandConstants::CARDS[row..row]*2
    when -1
      Pokerstats::HandConstants::CARDS[row..row] + Pokerstats::HandConstants::CARDS[col..col] + "s"
    end
  end
  
  def rowFromClassIndex(classIndex)
    classIndex / 13
  end
  
  def colFromClassIndex(classIndex)
    classIndex % 13
  end
  
  def self.classIndexFromRowAndCol(row, col)
    row*13 + col
  end
end