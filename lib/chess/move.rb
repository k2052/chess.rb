require 'ostruct'
require_relative 'piece'

module Chess
  class Move
    attr_accessor :from, :to, :color, :piece, :flags, :promotion, :captured, :board

    def self.from_san(san, board)
      moves = board.generate_moves
      # strip off any trailing move decorations: e.g Nf3+?!
      san.gsub!(/[+#?!=]+$/,'')
      moves.each do |move|
        return move if san == move.to_san
      end

      return nil
    end

    # Long Algebraic
    def self.from_uci(uci)
      if uci.length == 4
        new(Board::SQUARES[uci[0,2].to_sym], Board::SQUARES[uci[2,4].to_sym])
      elsif uci.length == 5
        promotion = Board::SYMBOLS[uci[4].to_sym]
        new(Board::SQUARES[uci[0, 2].to_sym], Board::SQUARES[uci[2, 4].to_sym], promotion)
      end
    end

    def initialize(from: from, to: to, promotion: nil, color: :w, board: Board.new, piece: nil, flags: nil)
      @from, @to, @color, @flags = from, to, color, flags
      @board = board
      piece ||= board[from]
      @piece = piece

      if promotion
        @flags   ||= Board::BITS[:PROMOTION]
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

    def inspect
      {from: from, to: to, color: color, piece: piece,
       flags: flags, promotion: promotion, captured: captured}
    end

    def to_san
      output = ''

      if flags & Board::BITS[:KSIDE_CASTLE] != 0
        output = 'O-O'
      elsif flags & Board::BITS[:QSIDE_CASTLE] != 0
        output = 'O-O-O'
      else
        disambiguator = board.get_disambiguator(self)

        unless piece.type == Board::PAWN
          output += piece.symbol + disambiguator
        end

        if flags & (Board::BITS[:CAPTURE] | Board::BITS[:EP_CAPTURE]) != 0
          if piece.type == Board::PAWN
            output += board.algebraic(from)[0]
          end

          output += 'x'
        end

        output += board.algebraic(to)

        if flags & Board::BITS[:PROMOTION] != 0
          output += '=' + promotion.to_s.upcase
        end
      end

      board.make_move(self)

      if board.in_check?
        if board.in_checkmate?
          output += '#'
        else
          output += '+'
        end
      end

      board.undo_move

      return output
    end
  end
end
