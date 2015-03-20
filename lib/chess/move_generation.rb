module Chess
  module MoveGeneration
    def generate_legal_moves(*args)
      moves = generate_pseudo_legal_moves(args)
      moves.select { |move| is_into_check(move) }
    end

    def is_pseudo_legal(move)
      # Source square must not be vacant.
      piece = piece_type_at(move.from_square)
      unless piece
        return false
      end

      # Get square masks.
      from_mask = BB_SQUARES[move.from_square]
      to_mask   = BB_SQUARES[move.to_square]

      # Check turn.
      if !occupied_co[turn] & from_mask
        return false
      end

      # Destination square can not be occupied.
      if occupied_co[turn] & to_mask
        return false
      end

      # Only pawns can promote and only on the backrank.
      if move.promotion
        if piece != PAWN
          return false
        end

        if turn == WHITE and rank_index(move.to_square) != 7
          return false
        elsif turn == BLACK and rank_index(move.to_square) != 0
          return false
        end
      end

      # Handle moves by piece type.
      if piece == KING
          # Castling.
          if turn == WHITE and move.from_square == E1
            if move.to_square == G1 and castling_rights & CASTLING_WHITE_KINGSIDE and !(BB_F1 | BB_G1) & occupied
              if !is_attacked_by(BLACK, E1) and not is_attacked_by(BLACK, F1) and !is_attacked_by(BLACK, G1)
                return true
              end
            elsif move.to_square == C1 and castling_rights & CASTLING_WHITE_QUEENSIDE and !(BB_B1 | BB_C1 | BB_D1) & occupied
              if !is_attacked_by(BLACK, E1) and not is_attacked_by(BLACK, D1) and !is_attacked_by(BLACK, C1)
                return true
              end
            end
          elsif turn == BLACK and move.from_square == E8
            if move.to_square == G8 and castling_rights & CASTLING_BLACK_KINGSIDE and !(BB_F8 | BB_G8) & occupied
              if not is_attacked_by(WHITE, E8) and not is_attacked_by(WHITE, F8) and not is_attacked_by(WHITE, G8)
                return true
              end
            elsif move.to_square == C8 and castling_rights & CASTLING_BLACK_QUEENSIDE and !(BB_B8 | BB_C8 | BB_D8) & occupied
              if not is_attacked_by(WHITE, E8) and not is_attacked_by(WHITE, D8) and not is_attacked_by(WHITE, C8)
                return true
              end
            end
          end

          return king_attacks_from(move.from_square) & to_mask
      elsif piece == PAWN
        # Require promotion type if on promotion rank.
        if !move.promotion
          if turn == WHITE and rank_index(move.to_square) == 7
            return false
          end
          if turn == BLACK and rank_index(move.to_square) == 0
            return false
          end
        end

        return pawn_moves_from(move.from_square) & to_mask
      elsif piece == QUEEN
        return queen_attacks_from(move.from_square) & to_mask
      elsif piece == ROOK
        return rook_attacks_from(move.from_square) & to_mask
      elsif piece == BISHOP
        return bishop_attacks_from(move.from_square) & to_mask
      elsif piece == KNIGHT
        return knight_attacks_from(move.from_square) & to_mask
      end
    end

    def generate_pseudo_legal_moves(castling: true, pawns: true, knights: true, bishops: true,
                                    rooks: true, queens: true, king: true)

      moves = []
      moves.push(*generate_white_moves)  if turn == WHITE
      moves.push(*generate_black_moves)  if turn == BLACk
      moves.push(*generate_knight_moves) if knights
      moves.push(*generate_bishop_moves) if bishops
      moves.push(*generate_rook_moves)   if rooks
      moves.push(*generate_queen_moves)  if queens
      moves.push(*generate_king_moves)   if king
      moves
    end

    def generate_white_moves(castling: true, pawns: true)
      moves = []
      moves.push(*generate_white_castling_moves) if castling
      moves.push(*generate_white_pawn_moves)     if pawns
      moves
    end

    def generate_white_castling_moves
      moves = []

      # Castling short.
      if castling_rights & CASTLING_WHITE_KINGSIDE and not (BB_F1 | BB_G1) & occupied
        if not is_attacked_by(BLACK, E1) and not is_attacked_by(BLACK, F1) and not is_attacked_by(BLACK, G1)
          moves << Move.new(E1, G1)
        end
      end

      # Castling long.
      if castling_rights & CASTLING_WHITE_QUEENSIDE and not (BB_B1 | BB_C1 | BB_D1) & occupied_l45
        if not is_attacked_by(BLACK, C1) and not is_attacked_by(BLACK, D1) and not is_attacked_by(BLACK, E1)
          moves << Move.new(E1, C1)
        end
      end

      moves
    end

    def generate_white_pawn_moves
      moves = []
      # En-passant moves.
      movers = pawns & occupied_co[WHITE]
      if ep_square
        moves = BB_PAWN_ATTACKS[BLACK][ep_square] & movers

        from_square = bit_scan(moves)
        while from_square do
          moves << Move.new(from_square, ep_square)
          from_square = bit_scan(moves, from_square + 1)
        end
      end

      # Pawn captures.

      # Right
      moves = shift_up_right(movers) & occupied_co[BLACK]
      to_square = bit_scan(moves)
      while to_square != -1 and to_square != nil do
        from_square = to_square - 9
        if rank_index(to_square) != 7
          moves << Move.new(from_square, to_square)
        else
          moves << Move.new(from_square, to_square, QUEEN)
          moves << Move.new(from_square, to_square, KNIGHT)
          moves << Move.new(from_square, to_square, ROOK)
          moves << Move.new(from_square, to_square, BISHOP)
        end
        to_square = bit_scan(moves, to_square + 1)
      end

      # Left
      moves = shift_up_left(movers) & occupied_co[BLACK]
      to_square = bit_scan(moves)
      while to_square != -1 and to_square != nil do
        from_square = to_square - 7
        if rank_index(to_square) != 7
          moves << Move.new(from_square, to_square)
        else
          moves << Move.new(from_square, to_square, QUEEN)
          moves << Move.new(from_square, to_square, KNIGHT)
          moves << Move.new(from_square, to_square, ROOK)
          moves << Move.new(from_square, to_square, BISHOP)
        end
        to_square = bit_scan(moves, to_square + 1)
      end

      # Pawns one forward.
      moves = shift_up(movers) & ~occupied
      movers = moves
      to_square = bit_scan(moves)
      while to_square != -1 and to_square != nil do
        from_square = to_square - 8
        if rank_index(to_square) != 7
          moves << Move.new(from_square, to_square)
        else
          moves << Move.new(from_square, to_square, QUEEN)
          moves << Move.new(from_square, to_square, KNIGHT)
          moves << Move.new(from_square, to_square, ROOK)
          moves << Move.new(from_square, to_square, BISHOP)
        end
        to_square = bit_scan(moves, to_square + 1)
      end

      # Pawns two forward.
      moves = shift_up(movers) & BB_RANK_4 & ~occupied
      to_square = bit_scan(moves)
      while to_square != -1 and to_square != nil do
        from_square = to_square - 16
        moves << Move.new(from_square, to_square)
        to_square = bit_scan(moves, to_square + 1)
      end

      moves
    end

    def generate_black_moves(castling: true, pawns: true)
      moves = []
      moves.push(*generate_black_castling_moves) if castling
      moves.push(*generate_black_pawn_moves)     if pawns
      moves
    end

    def generate_black_castling_moves
      moves = []

      # Castling short.
      if castling_rights & CASTLING_BLACK_KINGSIDE and not (BB_F8 | BB_G8) & occupied
        if not is_attacked_by(WHITE, E8) and not is_attacked_by(WHITE, F8) and not is_attacked_by(WHITE, G8)
          moves << Move.new(E8, G8)
        end
      end

      # Castling long.
      if castling_rights & CASTLING_BLACK_QUEENSIDE and not (BB_B8 | BB_C8 | BB_D8) & occupied
        if not is_attacked_by(WHITE, C8) and not is_attacked_by(WHITE, D8) and not is_attacked_by(WHITE, E8)
          moves << Move.new(E8, C8)
        end
      end

      moves
    end

    def generate_black_pawn_moves
      moves = []
      # En-passant moves.
      movers = pawns & occupied_co[BLACK]
      if ep_square
        moves = BB_PAWN_ATTACKS[WHITE][ep_square] & movers
        from_square = bit_scan(moves)
        while from_square != -1 and from_square != nil do
          moves << Move.new(from_square, ep_square)
          from_square = bit_scan(moves, from_square + 1)
        end
      end

      # Pawn captures.

      # Left
      moves = shift_down_left(movers) & occupied_co[WHITE]
      to_square = bit_scan(moves)
      while to_square != - 1 and to_square != nil do
        from_square = to_square + 9
        if rank_index(to_square) != 0
          moves << Move.new(from_square, to_square)
        else
          moves << Move.new(from_square, to_square, QUEEN)
          moves << Move.new(from_square, to_square, KNIGHT)
          moves << Move.new(from_square, to_square, ROOK)
          moves << Move.new(from_square, to_square, BISHOP)
        end
        to_square = bit_scan(moves, to_square + 1)
      end

      # Right
      moves = shift_down_right(movers) & occupied_co[WHITE]
      to_square = bit_scan(moves)
      while to_square != -1 and to_square != nil do
        from_square = to_square + 7
        if rank_index(to_square) != 0
          moves << Move.new(from_square, to_square)
        else
          moves << Move.new(from_square, to_square, QUEEN)
          moves << Move.new(from_square, to_square, KNIGHT)
          moves << Move.new(from_square, to_square, ROOK)
          moves << Move.new(from_square, to_square, BISHOP)
        end
        to_square = bit_scan(moves, to_square + 1)
      end

      # Pawns one forward.
      moves     = shift_down(movers) & ~occupied
      movers    = moves
      to_square = bit_scan(moves)
      while to_square != -1 and to_square != nil do
        from_square = to_square + 8
        if rank_index(to_square) != 0
          moves << Move.new(from_square, to_square)
        else
          moves << Move.new(from_square, to_square, QUEEN)
          moves << Move.new(from_square, to_square, KNIGHT)
          moves << Move.new(from_square, to_square, ROOK)
          moves << Move.new(from_square, to_square, BISHOP)
        end
        to_square = bit_scan(moves, to_square + 1)
      end

      # Pawns two forward.
      moves     = shift_down(movers) & BB_RANK_5 & ~occupied
      to_square = bit_scan(moves)
      while to_square != -1 and to_square != nil do
        from_square = to_square + 16
        moves << Move.new(from_square, to_square)
        to_square = bit_scan(moves, to_square + 1)
      end

      moves
    end

    def generate_knight_moves
      moves = []
      # Knight moves.
      movers = knights & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square != -1 and from_square != nil do
        moves = knight_attacks_from(from_square) & ~occupied_co[turn]
        to_square = bit_scan(moves)
        while to_square != -1 and to_square != nil do
          moves << Move.new(from_square, to_square)
          to_square = bit_scan(moves, to_square + 1)
        end
        from_square = bit_scan(movers, from_square + 1)
      end

      moves
    end

    def generate_bishop_moves
      moves = []
      # Bishop moves.
      movers = bishops & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square != -1 and from_square != nil do
        moves = bishop_attacks_from(from_square) & ~occupied_co[turn]
        to_square = bit_scan(moves)
        while to_square != - 1 and to_square != nil do
          moves << Move.new(from_square, to_square)
          to_square = bit_scan(moves, to_square + 1)
        end
        from_square = bit_scan(movers, from_square + 1)
      end

      moves
    end

    def generate_rook_moves
      moves = []
      movers = rooks & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square != -1 and from_square != nil do
        moves = rook_attacks_from(from_square) & ~occupied_co[turn]
        to_square = bit_scan(moves)
        while to_square != - 1 and to_square != nil do
          moves << Move.new(from_square, to_square)
          to_square = bit_scan(moves, to_square + 1)
        end
        from_square = bit_scan(movers, from_square + 1)
      end
      moves
    end

    def generate_queen_moves
      moves = []
      movers = queens & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square != -1 and from_square != nil do
        moves = queen_attacks_from(from_square) & ~occupied_co[turn]
        to_square = bit_scan(moves)
        while to_square != - 1 and to_square != nil do
          moves << Move.new(from_square, to_square)
          to_square = bit_scan(moves, to_square + 1)
        end
        from_square = bit_scan(movers, from_square + 1)
      end
      moves
    end

    def generate_king_moves
      moves = []
      # King moves.
      from_square = king_squares[turn]
      moves = king_attacks_from(from_square) & ~occupied_co[turn]
      to_square = bit_scan(moves)
      while to_square != - 1 and to_square != nil do
        moves << Move.new(from_square, to_square)
        to_square = bit_scan(moves, to_square + 1)
      end
      moves
    end

    def pseudo_legal_move_count
      # In a way duplicates generate_pseudo_legal_moves() in order to use
      # population counts instead of counting actually yielded moves.
      count = 0

      if turn == WHITE
        # Castling short.
        if castling_rights & CASTLING_WHITE_KINGSIDE and not (BB_F1 | BB_G1) & occupied
          if !is_attacked_by(BLACK, E1) and !is_attacked_by(BLACK, F1) and !is_attacked_by(BLACK, G1)
            count += 1
          end
        end

        # Castling long.
        if castling_rights & CASTLING_WHITE_QUEENSIDE and not (BB_B1 | BB_C1 | BB_D1) & occupied
          if !is_attacked_by(BLACK, C1) and !is_attacked_by(BLACK, D1) and !is_attacked_by(BLACK, E1)
            count += 1
          end
        end

        # En-passant moves.
        movers = pawns & occupied_co[WHITE]
        if ep_square
          moves = BB_PAWN_ATTACKS[BLACK][ep_square] & movers
          count += pop_count(moves)
        end

        # Pawn captures.
        moves = shift_up_right(movers) & occupied_co[BLACK]
        count += pop_count(moves & BB_RANK_8) * 3
        count += pop_count(moves)

        moves = shift_up_left(movers) & occupied_co[BLACK]
        count += pop_count(moves & BB_RANK_8) * 3
        count += pop_count(moves)

        # Pawns one forward.
        moves = shift_up(movers) & ~occupied
        movers = moves
        count += pop_count(moves & BB_RANK_8) * 3
        count += pop_count(moves)

        # Pawns two forward.
        moves = shift_up(movers) & BB_RANK_4 & ~occupied
        count += pop_count(moves)
      else
        # Castling short.
        if castling_rights & CASTLING_BLACK_KINGSIDE and !(BB_F8 | BB_G8) & occupied
          if !is_attacked_by(WHITE, E8) and !is_attacked_by(WHITE, F8) and !is_attacked_by(WHITE, G8)
            count += 1
          end
        end

        # Castling long.
        if castling_rights & CASTLING_BLACK_QUEENSIDE and !(BB_B8 | BB_C8 | BB_D8) & occupied
          if !is_attacked_by(WHITE, C8) and !is_attacked_by(WHITE, D8) and !is_attacked_by(WHITE, E8)
            count += 1
          end
        end

        # En-passant moves.
        movers = pawns & occupied_co[BLACK]
        if ep_square
          moves  = BB_PAWN_ATTACKS[WHITE][ep_square] & movers
          count += pop_count(moves)
        end

        # Pawn captures.
        moves = shift_down_left(movers) & occupied_co[WHITE]
        count += pop_count(moves & BB_RANK_1) * 3
        count += pop_count(moves)

        moves = shift_down_right(movers) & occupied_co[WHITE]
        count += pop_count(moves & BB_RANK_1) * 3
        count += pop_count(moves)

        # Pawns one forward.
        moves = shift_down(movers) & ~occupied
        movers = moves
        count += pop_count(moves & BB_RANK_1) * 3
        count += pop_count(moves)

        # Pawns two forward.
        moves = shift_down(movers) & BB_RANK_5 & ~occupied
        count += pop_count(moves)
      end

      # Knight moves.
      movers = knights & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square != -1 and from_square != nil do
        moves = knight_attacks_from(from_square) & ~occupied_co[turn]
        count += pop_count(moves)
        from_square = bit_scan(movers, from_square + 1)
      end

      # Bishop moves.
      movers = bishops & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square != -1 and from_square != nil do
        moves = bishop_attacks_from(from_square) & ~occupied_co[turn]
        count += pop_count(moves)
        from_square = bit_scan(movers, from_square + 1)
      end

      # Rook moves.
      movers = rooks & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square != -1 and from_square != nil do
        moves = rook_attacks_from(from_square) & ~occupied_co[turn]
        count += pop_count(moves)
        from_square = bit_scan(movers, from_square + 1)
      end

      # Queen moves.
      movers = queens & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square != -1 and from_square != nil do
        moves = queen_attacks_from(from_square) & ~occupied_co[turn]
        count += pop_count(moves)
        from_square = bit_scan(movers, from_square + 1)
      end

      # King moves.
      from_square = king_squares[turn]
      moves = king_attacks_from(from_square) & ~occupied_co[turn]
      count += pop_count(moves)

      count
    end

    def pawn_moves_from(square)
      targets = BB_PAWN_F1[turn][square] & ~occupied

      if targets
        targets |= BB_PAWN_F2[turn][square] & ~occupied
      end

      if !ep_square
        targets |= BB_PAWN_ATTACKS[turn][square] & occupied_co[turn ^ 1]
      else
        targets |= BB_PAWN_ATTACKS[turn][square] & (occupied_co[turn ^ 1] | BB_SQUARES[ep_square])
      end

      targets
    end

    def knight_attacks_from(square)
      BB_KNIGHT_ATTACKS[square]
    end

    def king_attacks_from(square)
      BB_KING_ATTACKS[square]
    end

    def rook_attacks_from(square)
      return (BB_RANK_ATTACKS[square][(occupied >> ((square & ~7) + 1)) & 63] |
              BB_FILE_ATTACKS[square][(occupied_l90 >> (((square & 7) << 3) + 1)) & 63])
    end

    def bishop_attacks_from(square)
      return (BB_R45_ATTACKS[square][(occupied_r45 >> BB_SHIFT_R45[square]) & 63] |
              BB_L45_ATTACKS[square][(occupied_l45 >> BB_SHIFT_L45[square]) & 63])
    end

    def queen_attacks_from(square)
      return rook_attacks_from(square) | bishop_attacks_from(square)
    end
  end
end
