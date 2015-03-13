module Chess
  module Moving
    def move(move)
      move_valid = false
      moves      = generate_moves

      move = Move.from_san(move, board: self) if move.is_a? String

      # loop through and see if move is valid
      moves.each do |_move|
        if move == _move
          move = _move
          move_valid = true
          break
        end
      end

      # failed to find move
      return false unless move_valid

      make_move(move)

      move
    end

    def push(move)
      history.push({
        move: move,
        kings: {b: kings[:b], w: kings[:w]},
        turn: turn,
        castling: {b: castling[:b], w: castling[:w]},
        ep_square: ep_square,
        half_moves: half_moves,
        move_number: move_number
      })
    end

    def make_move(move)
      us   = turn
      them = swap_color(us)
      push(move)

      board[move.to]   = board[move.from]
      board[move.from] = nil

      # if ep capture, remove the captured pawn
      unless move.flags & Board::BITS[:EP_CAPTURE] == 0
        if turn == Board::BLACK
          board[move.to - 16] = nil
        else
          board[move.to + 16] = nil
        end
      end

      # if pawn promotion, replace with new piece
      unless move.flags & Board::BITS[:PROMOTION] == 0
        board[move.to] = Piece.new(type: move.promotion, color: us)
      end

      # if we moved the king
      if board[move.to].type == Board::KING
        kings[board[move.to].color] = move.to

        # if we castled, move the rook next to the king
        if move.flags & Board::BITS[:KSIDE_CASTLE] != 0
          castling_to          = move.to - 1
          castling_from        = move.to + 1
          board[castling_to]   = board[castling_from]
          board[castling_from] = nil
        elsif move.flags & Board::BITS[:QSIDE_CASTLE] != 0
          castling_to          = move.to + 1
          castling_from        = move.to - 2
          board[castling_to]   = board[castling_from]
          board[castling_from] = nil
        end

        # turn off castling
        castling[us] = 0
      end

      # turn off castling if we move a rook
      if castling[us]
        Board::ROOKS[us].each do |rook|
          if move.from == rook[:square] && castling[us] & rook[:flag]
            castling[us] ^= rook[:flag]
            break
          end
        end
      end

      # turn off castling if we capture a rook
      if castling[them]
        Board::ROOKS[them].each do |rook|
          if move.to == rook[:square] && castling[them] & rook[:flag]
            castling[them] ^= rook[:flag]
            break
          end
        end
      end

      # if big pawn move, update the en passant square
      if move.flags & Board::BITS[:BIG_PAWN] != 0
        if turn == :b
          ep_square = move.to - 16
        else
          ep_square = move.to + 16
        end
      else
        ep_square = Board::EMPTY
      end

      # reset the 50 move counter if a pawn is moved or a piece is captured
      if move.piece.type == Board::PAWN
        @half_moves = 0
      elsif move.flags & (Board::BITS[:CAPTURE] | Board::BITS[:EP_CAPTURE]) != 0
        @half_moves = 0
      else
        @half_moves += 1
      end

      if turn == Board::BLACK
        move_number += 1
      end

      turn = swap_color(turn)
    end

    def undo_move
      old = history.pop()

      return if old == nil

      move        = old[:move]
      kings       = old[:kings]
      turn        = old[:turn]
      castling    = old[:castling]
      ep_square   = old[:ep_square]
      half_moves  = old[:half_moves]
      move_number = old[:move_number]

      us   = turn
      them = swap_color(turn)

      board[move.from] = board[move.to]
      board[move.from] = move.piece  # to undo any promotions
      board[move.to]   = nil

      if move.flags & Board::BITS[:CAPTURE]
        board[move.to] = Piece.new(type: move.captured, color: them)
      elsif move.flags & Board::BITS[:EP_CAPTURE]
        index

        if us == Board::BLACK
          index = move.to - 16
        else
          index = move.to + 16
        end

        board[index] = Piece.new(type: Board::PAWN, color: them)
      end

      if move.flags & (Board::BITS[:KSIDE_CASTLE] | Board::BITS[:QSIDE_CASTLE])
        castling_to, castling_from = nil, nil

        if move.flags & Board::BITS[:KSIDE_CASTLE]
          castling_to   = move.to + 1
          castling_from = move.to - 1
        elsif move.flags & Board::BITS[:QSIDE_CASTLE]
          castling_to   = move.to - 2
          castling_from = move.to + 1
        end

        board[castling_to]   = board[castling_from]
        board[castling_from] = nil
      end

      return move
    end
    alias_method :undo, :undo_move

    def history
      reversed_history = []
      move_history     = []

      while history.length > 0 do
        reversed_history.push(undo_move)
      end

      while reversed_history.length > 0 do
        move = reversed_history.pop()
        move_
        (move)

        make_move(move)
      end

      return move_history
    end
  end
end
