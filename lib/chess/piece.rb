require_relative 'board'

module Chess
  class Piece
    attr_accessor :type, :color

    def initialize(type:, color:)
      @type, @color = type, color
      raise StandardError, 'Invalid Piece' unless Board::SYMBOLS[@type]
    end

    def symbol
      if @color == 'w'
        Board::SYMBOLS[@type].upcase
      else
        Board::SYMBOLS[@type]
      end
    end

    def ==(other_piece)
      if other_piece.is_a? Piece
        @type == other_piece.type
      else
        @type == other_piece
      end
    end
  end
end
