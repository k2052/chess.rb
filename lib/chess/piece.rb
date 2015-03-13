require_relative 'board'

module Chess
  class Piece
    attr_accessor :type, :color

    def initialize(type:, color:)
      @type, @color = type.to_s.downcase.to_sym, color
      raise StandardError, 'Invalid Piece' unless Board::SYMBOLS.include? @type.to_s
    end

    def symbol
      if color == :w
        @type.to_s.upcase
      else
        @type.to_s.downcase
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
