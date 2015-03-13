module Chess
  module MoveGeneration
    def generate_pawn_moves(from, to, flags)
      moves = []
      # if pawn promotion
      if rank(to) == Board::RANK_8 || rank(to) == Board::RANK_1
        pieces = [Board::QUEEN, Board::ROOK, Board::BISHOP, Board::KNIGHT]
        pieces.each do |piece|
          moves << Move.new(from: from, to: to, board: self, flags: flags, piece: piece)
        end
      else
        moves << Move.new(from: from, to: to, board: self, flags: flags)
      end

      moves
    end

    def generate_moves(legal: false, square: nil)
      moves       = []
      us          = turn
      them        = swap_color(us)
      square = square.to_sym if square

      Board::SQUARES.each do |square_name, squarei|
        piece = board[square_i]

        if piece.type == Board::PAWN
          moves.push(*generate_pawn_moves)
        else
          moves << Move.new(from: from, to: to, board: self, flags: flags)
        end
      end

      return moves unless legal
      filter_legal_moves(moves)
    end
    alias_method :moves, :generate_moves

    def filter_legal_moves(moves)
      # filter out illegal moves
      legal_moves = []
      moves.each do |move|
        make_move(move)
        unless king_attacked?(us)
          legal_moves.push(move)
        end

        undo_move
      end
      legal_moves
    end

    def get_disambiguator(move)
      moves = generate_moves

      from  = move.from
      to    = move.to
      piece = move.piece

      ambiguities = 0
      same_rank   = 0
      same_file   = 0

      moves.each do |move|
        ambig_from  = move.from
        ambig_to    = move.to
        ambig_piece = move.piece

        # if a move of the same piece type ends on the same to square, we'll
        # need to add a disambiguator to the algebraic notation
        if piece == ambig_piece && from != ambig_from && to == ambig_to
          ambiguities += 1

          if rank(from) == rank(ambig_from)
            same_rank += 1
          end

          if file(from) == file(ambig_from)
            same_file += 1
          end
        end
      end

      if ambiguities > 0
        # if there exists a similar moving piece on the same rank and file as
        # the move in question, use the square as the disambiguator
        if same_rank > 0 && same_file > 0
          return algebraic(from)
        # if the moving piece rests on the same file, use the rank symbol as the disambiguator
        elsif same_file > 0
          return algebraic(from)[1]
        # else use the file symbol
        else
          return algebraic(from)[0]
        end
      end

      return 0
    end
  end
end
