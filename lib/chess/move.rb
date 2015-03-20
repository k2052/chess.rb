require 'ostruct'
require_relative 'piece'

module Chess
  class Move
    attr_accessor :from_square, :to_square, :promotion

    def self.from_uci(uci)
      ###
      # Parses an UCI string.
      #
      # Raises `ValueError` if the UCI string is invalid.
      ###
      if uci == "0000"
        return null
      elsif uci.length == 4
        return new(Board::SQUARE_NAMES.index(uci[0,2].to_sym), Board::SQUARE_NAMES.index(uci[2,4].to_sym))
      elsif uci.length == 5
        promotion = Board::PIECE_SYMBOLS.index(uci[4].to_sym)
        return new(Board::SQUARE_NAMES.index(uci[0,2].to_sym), Board::SQUARE_NAMES.index(uci[2,2].to_sym), promotion)
      else
        raise ArgumentError, "expected uci string to be of length 4 or 5"
      end
    end

    def self.null
      ###
      # Gets a null move.
      #
      # A null move just passes the turn to the other side (and possibly
      # forfeits en-passant capturing). Null moves evaluate to `False` in
      # boolean contexts.
      #
      # >>> bool(chess.Move.null())
      # False
      #
      return new(0, 0, nil)
    end

    ###
    # Represents a move from a square to a square and possibly the promotion piece
    # type.
    #
    # Castling moves are identified only by the movement of the king.
    #
    # Null moves are supported.
    ###
    def initialize(from_square, to_square, promotion = nil)
      @from_square = from_square
      @to_square   = to_square
      @promotion   = promotion
    end

    def to_uci
      ###
      # Gets an UCI string for the move.
      #
      # For example a move from A7 to A8 would be `a7a8` or `a7a8q` if it is
      # a promotion to a queen. The UCI representatin of null moves is `0000`.
      ###
      if from_square != 0
        res = ''
        res << Board::SQUARE_NAMES[self.from_square].to_s
        res << Board::SQUARE_NAMES[self.to_square].to_s
        res << Board::PIECE_SYMBOLS[self.promotion].to_s if promotion
        res
      else
        return '0000'
      end
    end

    def to_bool
      return self.from_square || self.to_square || self.promotion
    end

    def equal?(other)
      self == other
    end

    def ==(other)
      if other.respond_to? :from_square
        return from_square == other.from_square && to_square == other.to_square && promotion == other.promotion
      else
        return false
      end
    end

    def !=(other)
      return ! equal?(other)
    end

    def to_s
      return to_uci
    end

    def to_hash_s
      return self.to_square | self.from_square << 6 | self.promotion << 12
    end
  end
end
