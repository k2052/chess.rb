require_relative 'board'

module Chess
  module State
    def attacked?(color, square)
      i = Board::SQUARES[:a8]
      while i <= Board::SQUARES[:h1] do
        # did we run off the end of the board */
        if i & 0x88
          i += 7
          next
        end

        # if empty square or wrong color */
        next if (board[i].nil? || board[i].color != color)

        piece      = board[i]
        difference = i - square
        index      = difference + 119

        if Board::ATTACKS[index] & (1 << Board::SHIFTS[piece.type])
          if piece.type == Board::PAWN
            if difference > 0
              return true if piece.color == Board::WHITE
            elsif piece.color == Board::BLACK
              return true
            end
            next
          end

          # if the piece is a knight or a king */
         return true if piece.type == 'n' || piece.type == 'k'

          offset = Board::RAYS[index]
          j      = i + offset

          blocked = false
          while j != square do
            unless board[j].nil?
              blocked = true
              break
            end
            j += offset
          end

          return true unless blocked
        end
      end

      return false
    end

    def king_attacked?(color)
      return attacked?(swap_color(color), kings[color])
    end

    def in_check?
      return king_attacked?(turn)
    end

    def in_checkmate?
      return in_check? && generate_moves.length == 0
    end

    def in_stalemate?
      return !in_check? && generate_moves().length == 0
    end

    def insufficient_material?
      pieces     = {}
      bishops    = []
      num_pieces = 0
      sq_color   = 0

      i = Board::SQUARES[:a8]
      while i <= Board::SQUARES[:h1] do
        sq_color = (sq_color + 1) % 2
        if i & 0x88
          i += 7
          next
        end

        piece = board[i]
        if piece
          pieces[piece.type] = pieces.include? piece.type ? pieces[piece.type] + 1 : 1
          bishops.push(sq_color) if piece.type == Board::BISHOP
          num_pieces += 1
        end

        i += 1
      end

      # k vs. k */
      return true if num_pieces == 2

      # k vs. kn .... or .... k vs. kb */
      if num_pieces == 3 && (pieces[Board::BISHOP] == 1 || pieces[Board::KNIGHT] == 1)
        return true
      end

      # kb vs. kb where any number of bishops are all on the same color */
      if num_pieces == pieces[Board::BISHOP] + 2
        sum = 0
        len = bishops.length
        i = 0
        while i < len do
          sum += bishops[i]
          i += 1
        end

        return true if sum == 0 || sum == len
      end

      return false
    end

    def in_threefold_repetition?
      # TODO: while this def is fine for casual use, a better
      # implementation would use a Zobrist key (instead of FEN). the
      # Zobrist key would be maintained in the make_move/undo_move functions,
      # avoiding the costly that we do below.
      #
      moves      = []
      positions  = {}
      repetition = false

      while true do
        move = undo_move()
        break unless move
        moves.push(move)
      end

      while true do
        # remove the last two fields in the FEN string, they're not needed
        # when checking for draw by rep */
        fen = generate_fen.split(' ').slice(0,4).join(' ')

        # has the position occurred three or move times */
        positions[fen] = positions.include?(fen) ? positions[fen] + 1 : 1
        if positions[fen] >= 3
          repetition = true
        end

        break if moves.empty?

        make_move(moves.pop())
      end

      return repetition
    end


    def in_draw?
      return half_moves >= 100 ||
             in_stalemate? ||
             insufficient_material? ||
             in_threefold_repetition?
    end

    def game_over?
      return half_moves >= 100 ||
             in_checkmate? ||
             in_stalemate? ||
             insufficient_material? ||
             in_threefold_repetition?
   end
  end
end
