require 'iconv'
require File.expand_path(File.dirname(__FILE__) + '/hand_history')
module Pokerstats
  class PokerstarsFile
    include Enumerable

    POKERSTARS_HEADER_PATTERN = /PokerStars Game #([0-9]+)/

    def self.open(filename, starting_at = 0, &block)
      new(filename, starting_at).open(starting_at, &block)
    end

    def initialize(filename, starting_at = 0, transliterate_from = "ISO-8859-1", transliterate_to = "ASCII//TRANSLIT//IGNORE")
      @filename = File.expand_path(filename)
      @lastline = nil
      @lines = []
      @transliterator = Iconv.new(transliterate_to, transliterate_from)
    end

    def open_file_and_verify_first_line(starting_at = 0)
      @file = File.open(@filename, "r")
      self.pos=starting_at
    end

    def open(starting_at = 0)
      open_file_and_verify_first_line(starting_at)
      if block_given?
        begin
          yield self
        ensure
          close
        end
      end
      self
    end

    def closed?
      @file.closed?
    end

    def pos
      return @file.pos if @lastline.nil?
      @file.pos - @lastline.size - 1
    end

    def pos=(index)
      @file.pos=index unless pos == index
      @lastline = read_and_chomp_next_line_from_file
      unless @lastline && @lastline =~ POKERSTARS_HEADER_PATTERN
        close
        raise "hand record must begin with a valid header line"
      end
      @lines = [@lastline]
    end

    def eof?
      @lastline.nil?
    end

    def first(starting_at = 0)
      open(starting_at) do
        return next_handrecord
      end
    end

    def each
      yield next_handrecord
      yield next_handrecord until @lastline.nil?
    end

    def next_handrecord
      starting_at = pos
      until @file.eof?
        @lastline = read_and_chomp_next_line_from_file
        break if @lastline =~ POKERSTARS_HEADER_PATTERN
        @lines << @lastline unless @lastline.empty?
      end
      result, @lines = HandHistory.new(@lines, @filename, starting_at), [@lastline]
      if @file.eof?
        @lastline = nil
        @index_of_last_header = nil
        @lines = []
      else
        @index_of_last_header = @file.pos-@lastline.size-1
        @lines = [@lastline]
      end
      result
    end

    def close
      @file.close unless @file.closed?
    end
  
    private
  
      def read_and_chomp_next_line_from_file
        @transliterator.iconv(@file.readline.chomp!)
      end
  end
end