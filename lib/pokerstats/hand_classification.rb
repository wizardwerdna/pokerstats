require File.expand_path(File.dirname(__FILE__) + "/hand_constants")
module Pokerstats  
  def class_index_from_hand_string(hand_string)
      return class_index_from_hand_string!(hand_string)
  rescue ArgumentError
      nil
  end
  
  def class_index_from_hand_string!(hand_string)
    class_index_from_class_string!(class_string_from_hand_string!(hand_string))
  end
  
  def class_string_from_hand_string(hand_string)
      class_string_from_hand_string!(hand_string)
  rescue
      nil
  end
  
  def class_string_from_hand_string!(hand_string)
    raise ArgumentError, "hand_string '#{hand_string}' must be a String" unless hand_string.kind_of?(String)
    hand_string = hand_string.gsub(/ /,'')
    hand_string = hand_string.upcase
    raise ArgumentError, "hand_string '#{hand_string}' must have 4 non-blank characters" unless hand_string.size==4
    first_rank, first_suit, second_rank, secondSuit = *hand_string.split('')
    raise ArgumentError, "hand_string #{hand_string.inspect} suit characters #{first_suit.inspect} and #{secondSuit.inspect} must be from CDHS" unless "CDHS".include?(first_suit) && "CDHS".include?(secondSuit)
    first_rank_index, second_rank_index = Pokerstats::HandConstants::CARDS.index(first_rank), Pokerstats::HandConstants::CARDS.index(second_rank) 
    raise ArgumentError, "hand_string '#{hand_string}' rank characters must be from AKQJT98765432" if first_rank_index.nil? || second_rank_index.nil?
    if first_rank==second_rank
      raise ArgumentError, "hand_string '#{hand_string}' cards must be different" if first_suit == secondSuit || !"CDHS".include?(first_suit)
      first_rank*2
    else
      if first_rank_index > second_rank_index
        result = first_rank + second_rank
      else
        result = second_rank + first_rank
      end
      if first_suit == secondSuit
        result += "s"
      end
      result
    end
  end
  
  def class_index_from_class_string(class_string)
      class_index_from_class_string!(class_string)
  rescue
      nil
  end
  
  def class_index_from_class_string!(class_string)
    raise ArgumentError, "class_string #{class_string.inspect} must be a String" unless class_string.kind_of?(String)
    class_string.upcase!
    first = Pokerstats::HandConstants::CARDS.index(class_string[0..0])
    second = Pokerstats::HandConstants::CARDS.index(class_string[1..1])
    first, second = second, first if first > second
    raise ArgumentError, "class_string is malformed" if first.nil? || second.nil?
    case class_string[2..2]
    when "S","P"
      13*first+second
    when "O",""
      13*second+first      
    else raise ArgumentError, "class_string is malformed"
    end
  end
  
  def class_string_from_class_index(class_index)
      class_string_from_class_index!(class_index)
  rescue ArgumentError
      nil
  end
  
  def class_string_from_class_index!(class_index)
    raise ArgumentError, "class_index must be an integer" unless class_index.kind_of? Integer
    row, col = row_from_class_index(class_index), col_from_class_index(class_index)
    case row <=> col
    when 1
      Pokerstats::HandConstants::CARDS[col..col] + Pokerstats::HandConstants::CARDS[row..row] + "o"
    when 0
      Pokerstats::HandConstants::CARDS[row..row]*2
    when -1
      Pokerstats::HandConstants::CARDS[row..row] + Pokerstats::HandConstants::CARDS[col..col] + "s"
    end
  end
  
  def row_from_class_index(classIndex)
    classIndex / 13
  end
  
  def col_from_class_index(classIndex)
    classIndex % 13
  end
  
  def class_index_from_row_and_col(row, col)
    row*13 + col
  end
end