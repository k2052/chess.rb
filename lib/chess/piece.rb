require_relative 'board'

module Chess
  class Piece
    attr_accessor :piece_type, :color

    def self.from_symbol(symbol)
      ###
      # Creates a piece instance from a piece symbol.
      #
      # Raises `ValueError` if the symbol is invalid
      ###{}
      if symbol.downcase == symbol
        return new(Board::PIECE_SYMBOLS.index(symbol.downcase.to_sym), Board::BLACK)
      else
        return new(Board::PIECE_SYMBOLS.index(symbol.downcase.to_sym), Board::WHITE)
      end
    end

    def initialize(piece_type, color)
      @piece_type = piece_type
      @color      = color
    end

    def symbol
      ###
      # Gets the symbol `P`, `N`, `B`, `R`, `Q` or `K` for white pieces or the
      # lower-case variants for the black pieces.
      ###
      if color == Board::WHITE
        return Board::PIECE_SYMBOLS[piece_type].to_s.upcase
      else
        return Board::PIECE_SYMBOLS[piece_type].to_s
      end
    end

    def to_hash_s
      return self.piece_type * (self.color + 1)
    end

    def to_s
      return self.symbol
    end

    def ==(other)
      if other.respond_to? :piece_type
        return self.piece_type == other.piece_type && self.color == other.color
      else
        return false
      end
    end

    def not_equal?(other)
      return !(self == other)
    end
  end
end
