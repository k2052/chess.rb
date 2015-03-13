require_relative 'board'

module Chess
  module State
    def load_position(fen)
      clear

      tokens   = fen.split(' ')
      position = tokens[0]
      square   = 0
      valid    = Board::SYMBOLS + '12345678/'

      return false unless Fen.valid?(fen)

      piece_count = 0
      position.chars.each do |piece|
        if piece == '/'
          square += 8
        elsif piece.is_numeric?
          square += piece.to_i
        else
          color = piece.upcase == piece ? Board::WHITE : Board::BLACK
          put(Piece.new(type: piece.downcase, color: color), algebraic(square))
          square += 1
        end
      end

      turn = tokens[1]

      castling[:w] |= Board::BITS[:KSIDE_CASTLE] if tokens[2].include?('K')
      castling[:w] |= Board::BITS[:QSIDE_CASTLE] if tokens[2].include?('Q')
      castling[:b] |= Board::BITS[:KSIDE_CASTLE] if tokens[2].include?('k')
      castling[:b] |= Board::BITS[:QSIDE_CASTLE] if tokens[2].include?('q')

      ep_square   = tokens[3] == '-' ? Board::EMPTY : Board::SQUARES[tokens[3].to_sym]
      half_moves  = tokens[4].to_i
      move_number = tokens[5].to_i

      update_setup(to_fen)

      true
    end

    def to_fen
      empty = 0
      fen   = ''

      Board::SQUARES.each do |key, sqi|
        empty = 0

        if board[sqi].nil?
          empty += 1
        else
          if empty > 0
            fen << empty
            empty = 0
          end

          piece = board[sqi]
          fen << piece.symbol.to_s
        end

        if sqi & 0x88
          fen << empty if empty > 0
          fen << '/' unless sqi == Board::SQUARES[:h1]

          empty = 0
        end
      end

      cflags  = ''
      cflags << 'K' if castling[Board::WHITE] & Board::BITS[:KSIDE_CASTLE]
      cflags << 'Q' if castling[Board::WHITE] & Board::BITS[:QSIDE_CASTLE]
      cflags << 'k' if castling[Board::BLACK] & Board::BITS[:KSIDE_CASTLE]
      cflags << 'q' if castling[Board::BLACK] & Board::BITS[:QSIDE_CASTLE]

      # do we have an empty castling flag?
      cflags  = cflags || '-'
      epflags = (ep_square == Board::EMPTY) ? '-' : algebraic(ep_square)

      [fen, turn, cflags, epflags, half_moves, move_number].join(' ')
    end

    def update_setup(fen)
      return if history.length > 0

      if fen != Board::DEFAULT_POSITION
        header['SetUp'] = '1'
        header['FEN']   = fen
      else
        header.delete('SetUp')
        header.delete('FEN')
      end
    end

    def attacked?(color, square)
      Board::SQUARES.each do |_, sqi|
        # if empty square or wrong color
        next if (board[sqi].nil? || board[sqi].color != color)

        piece      = board[sqi]
        difference = sqi - square
        index      = difference + 119

        if Board::ATTACKS[index] & (1 << Board::SHIFTS[piece.type]) != 0
          puts 'never here?'
          if piece.type == Board::PAWN
            if difference > 0
              return true if piece.color == Board::WHITE
            else
              if piece.color == Board::BLACK
                return true
              end
            end
          end

          # if the piece is a knight or a king
          return true if piece.type == :n || piece.type == :k

          offset = Board::RAYS[index]
          j      = sqi + offset

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
      return in_check? && generate_moves.empty?
    end

    def in_stalemate?
      return !in_check? && generate_moves.empty?
    end

    def insufficient_material?
      pieces     = {}
      bishops    = []
      num_pieces = 0
      sq_color   = 0

      Board::SQUARES.each do |_, sqi|
        sq_color = (sq_color + 1) % 2

        piece = board[sqi]
        if piece
          pieces[piece.type] = pieces.include? piece.type ? pieces[piece.type] + 1 : 1
          bishops.push(sq_color) if piece.type == Board::BISHOP
          num_pieces += 1
        end
      end

      # k vs. k
      return true if num_pieces == 2

      # k vs. kn .... or .... k vs. kb
      if num_pieces == 3 && (pieces[Board::BISHOP] == 1 || pieces[Board::KNIGHT] == 1)
        return true
      end

      # kb vs. kb where any number of bishops are all on the same color
      if num_pieces == pieces[Board::BISHOP] + 2
        sum = 0
        bishops.each do |bishop|
          sum += bishop
        end

        return true if sum == 0 || sum == len
      end

      return false
    end

    def in_threefold_repetition?
      # TODO: while this def is fine for casual use, a better
      # implementation would use a Zobrist key (instead of FEN). the
      # Zobrist key would be maintained in the make_move/undo_move functions
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
