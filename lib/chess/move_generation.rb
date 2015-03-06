module Chess
  module MoveGeneration
    def add_move(board, from, to, flags)
      moves = []
      # if pawn promotion
      if (board[from].piece.type == Board::PAWN) && (rank(to) == Board::RANK_8 || rank(to) == Board::RANK_1)
        pieces = [Board::QUEEN, Board::ROOK, Board::BISHOP, Board::KNIGHT]
        pieces.each do |piece|
          moves << Move.new(from: from, to: to, board: board, flags: flags, piece: piece)
        end
      else
        moves << Move.new(from: from, to: to, board: board, flags: flags)
      end

      moves
    end

    def generate_moves(legal: false, square: nil)
      moves       = []
      us          = turn
      them        = swap_color(us)
      second_rank = {b: Board::RANK_7, w: Board::RANK_2}

      first_sq      = Board::SQUARES[:a8]
      last_sq       = Board::SQUARES[:h1]
      single_square = false

      # are we generating moves for a single square?
      if square
        if Board::SQUARES.include? square
          first_sq = last_sq = Board::SQUARES[square]
          single_square = true
        else
          # invalid square
          return []
        end
      end

      Board::SQUARES.each do |sqname, sqi|
        piece = board[sqi]

        if piece.nil? || piece.color != us
          next
        end

        if piece.type == Board::PAWN
          # single square, non-capturing
          square = sqi + Board::PAWN_OFFSETS[us][0]

          unless board[square]
            moves.push(*add_move(board, sqi, square, Board::BITS[:NORMAL]))

            # double square
            square = sqi + Board::PAWN_OFFSETS[us][1]
            if second_rank[us] == rank(i) && board[square].nil?
              moves.push(*add_move(board, sqi, square, Board::BITS[:BIG_PAWN]))
            end
          end

          # pawn captures
          j = 2
          while j < 4 do
            square = sqi + Board::PAWN_OFFSETS[us][j]
            next if square & 0x88

            if board[square] && board[square].color == them
              moves.push(*add_move(board, sqi, square, Board::BITS[:CAPTURE]))
            elsif square == ep_square
              moves.push(*add_move(board, sqi, ep_square, Board::BITS[:EP_CAPTURE]))
            end
          end
        else
          Board::PIECE_OFFSETS[piece.type].each do |offset|
            square = sqi

            while true do
              square += offset
              break if square & 0x88

              if !board[square]
                moves.push(*add_move(board, sqi, square, Board::BITS[:NORMAL]))
              else
                next if board[square].color == us
                moves.push(*add_move(board, sqi, square, Board::BITS[:CAPTURE]))
                break
              end

              # break, if knight or king
              break if piece.type == 'n' || piece.type == 'k'
            end
          end
        end
      end

      # check for castling if: a) we're generating all moves, or b) we're doing
      # single square move generation on the king's square

      if !single_square || last_sq == kings[us]
        # king-side castling
        if castling[us] & Board::BITS[:KSIDE_CASTLE]
          castling_from = kings[us]
          castling_to   = castling_from + 2

          if (board[castling_from + 1].nil? &&
              board[castling_to].nil? &&
              !attacked?(them, kings[us]) &&
              !attacked?(them, castling_from + 1) &&
              !attacked?(them, castling_to))

            moves.push(*add_move(board, kings[us], castling_to, Board::BITS[:KSIDE_CASTLE]))
          end
        end

        # queen-side castling
        if castling[us] & Board::BITS[:QSIDE_CASTLE]
          castling_from = kings[us]
          castling_to   = castling_from - 2

          if (board[castling_from - 1].nil? &&
              board[castling_from - 2].nil? &&
              board[castling_from - 3].nil? &&
              !attacked?(them, kings[us]) &&
              !attacked?(them, castling_from - 1) &&
              !attacked?(them, castling_to))

            moves.push(*add_move(board, kings[us], castling_to, Board::BITS[:QSIDE_CASTLE]))
          end
        end
      end

      # return all pseudo-legal moves (this includes moves that allow the king to be captured

      return moves unless legal

      # filter out illegal moves
      legal_moves = []
      moves.each do |move|
        make_move(move)
        unless king_attacked?(us)
          legal_moves.push(move)
        end

        undo_move
      end

      return legal_moves
    end

    def get_disambiguator(move)
      moves = generate_moves

      from  = move.from
      to    = move.to
      piece = move.piece

      ambiguities = 0
      same_rank   = 0
      same_file   = 0

      i = 0
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

      return ''
    end

    # convert a move from 0x88 coordinates to Standard Algebraic Notation
    # (SAN)
    def move_to_san(move)
      output = ''

      if move.flags & Board::BITS[:KSIDE_CASTLE]
        output = 'O-O'
      elsif move.flags & Board::BITS[:QSIDE_CASTLE]
        output = 'O-O-O'
      else
        disambiguator = get_disambiguator(move)

        if move.piece != Board::PAWN
          output += move.piece.type.upcase + disambiguator
        end

        if move.flags & (Board::BITS[:CAPTURE] | Board::BITS[:EP_CAPTURE])
          if move.piece.type == Board::PAWN
            output += algebraic(move.from)[0]
          end

          output += 'x'
        end

        output += algebraic(move.to)

        if move.flags & Board::BITS[:PROMOTION]
          output += '=' + move.promotion.upcase
        end
      end

      make_move(move)

      if in_check?
        if in_checkmate?
          output += '#'
        else
          output += '+'
        end
      end

      undo_move

      return output
    end

    def push(move)
      history.push({
        move: move,
        kings: {b: kings.b, w: kings.w},
        turn: turn,
        castling: {b: castling.b, w: castling.w},
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
      if move.flags & Board::BITS[:EP_CAPTURE]
        if turn == Board::BLACK
          board[move.to - 16] = nil
        else
          board[move.to + 16] = nil
        end
      end

      # if pawn promotion, replace with new piece
      if move.flags & Board::BITS[:PROMOTION]
        board[move.to] = {type: move.promotion, color: us}
      end

      # if we moved the king
      if board[move.to].type == Board::KING
        kings[board[move.to].color] = move.to

        # if we castled, move the rook next to the king
        if move.flags & Board::BITS[:KSIDE_CASTLE]
          castling_to          = move.to - 1
          castling_from        = move.to + 1
          board[castling_to]   = board[castling_from]
          board[castling_from] = nil
        elsif move.flags & Board::BITS[:QSIDE_CASTLE]
          castling_to          = move.to + 1
          castling_from        = move.to - 2
          board[castling_to]   = board[castling_from]
          board[castling_from] = nil
        end

        # turn off castling
        castling[us] = ''
      end

      # turn off castling if we move a rook
      if castling[us]
        i = 0
        while i < Board::ROOKS[us].length do
          if move.from == Board::ROOKS[us][i].square && castling[us] & Board::ROOKS[us][i].flag
            castling[us] ^= Board::ROOKS[us][i].flag
            break
          end
        end
      end

      # turn off castling if we capture a rook
      if castling[them]
        i = 0
        while i < Board::ROOKS[them].length do
          if move.to == Board::ROOKS[them][i].square && castling[them] & Board::ROOKS[them][i].flag
            castling[them] ^= Board::ROOKS[them][i].flag
            break
          end
        end
      end

      # if big pawn move, update the en passant square
      if move.flags & Board::BITS[:BIG_PAWN]
        if turn == 'b'
          ep_square = move.to - 16
        else
          ep_square = move.to + 16
        end
      else
        ep_square = Board::EMPTY
      end

      # reset the 50 move counter if a pawn is moved or a piece is captured
      if move.piece.type == Board::PAWN
        half_moves = 0
      elsif move.flags & (Board::BITS[:CAPTURE] | Board::BITS[:EP_CAPTURE])
        half_moves = 0
      else
        half_moves += 1
      end

      if turn == Board::BLACK
        move_number += 1
      end

      turn = swap_color(turn)
    end

    def undo_move
      old = history.pop()

      return if old == nil

      move        = old.move
      kings       = old.kings
      turn        = old.turn
      castling    = old.castling
      ep_square   = old.ep_square
      half_moves  = old.half_moves
      move_number = old.move_number

      us   = turn
      them = swap_color(turn)

      board[move.from]      = board[move.to]
      board[move.from].type = move.piece  # to undo any promotions
      board[move.to]        = nil

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

      if move.flags & (Board::BITS.KSIDE_CASTLE | Board::BITS.QSIDE_CASTLE)
        castling_to, castling_from = nil, nil

        if move.flags & Board::BITS.KSIDE_CASTLE
          castling_to   = move.to + 1
          castling_from = move.to - 1
        elsif move.flags & Board::BITS.QSIDE_CASTLE
          castling_to   = move.to - 2
          castling_from = move.to + 1
        end

        board[castling_to]   = board[castling_from]
        board[castling_from] = nil
      end

      return move
    end

    def to_ascii
      s = '   +------------------------+\n'

      i = Board::SQUARES[:a8]
      while i <= Board::SQUARES[:h1] do
        # display the rank
        if file(i) == 0
          s += ' ' + '87654321'[rank(i)] + ' |'
        end

        # empty piece
        if board[i] == nil
          s += ' . '
        else
          piece = board[i]
          s += ' ' + piece.symbol + ' '
        end

        if (i + 1) & 0x88
          s += '|\n'
          i += 8
        end

        i += 1
      end

      s += '   +------------------------+\n'
      s += '     a  b  c  d  e  f  g  h\n'

      return s
    end

    def history
      reversed_history = []
      move_history     = []

      while history.length > 0 do
        reversed_history.push(undo_move)
      end

      while reversed_history.length > 0 do
        move = reversed_history.pop()
        move_history.push(move)

        make_move(move)
      end

      return move_history
    end
  end
end
