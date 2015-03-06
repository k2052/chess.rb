require 'ostruct'
require_relative 'piece'

module Chess
  class Move
    attr_accessor :from, :to, :color, :piece, :flags, :promotion, :captured

    def self.from_uci(uci)
      if uci.length == 4
        new(Board::SQUARES[uci[0,2].to_sym], Board::SQUARES[uci[2,4].to_sym])
      elsif uci.length == 5
        promotion = Board::SYMBOLS[uci[4].to_sym]
        new(Board::SQUARES[uci[0, 2].to_sym], Board::SQUARES[uci[2, 4].to_sym], promotion)
      end
    end

    def initialize(from: from, to: to, promotion:, color: :w, board: Board.new, piece: nil, flags: nil)
      @from, @to, @color, @flags = from, to, color, flags
      piece ||= board[from].piece
      @piece = piece

      if promotion
        @flags  ||= Board::BITS[:PROMOTION]
        @promotion = promotion
      end

      if board[to]
        @captured = board[to].type
      elsif @flags & Board::BITS[:EP_CAPTURE]
        @captured = Board::PAWN
      end
    end

    def white?
      color == 'w'
    end

    def black?
      color == 'b'
    end

    def to_pretty
      pretty = OpenStruct.new(san: to_san, to: board.algebraic(to), from: board.algebraic(from), flags: @flags)

      flags = []

      Board::BITS.each do |flag|
        if Board::BITS[flag] & pretty.flags
          flags << Board::FLAGS[flag]
        end
      end

      pretty.flags = flags

      return pretty
    end

    def to_san
    end
  end
end
