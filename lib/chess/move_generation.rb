module Chess
  module MoveGeneration
    def generate_legal_moves(*args)
      moves = generate_pseudo_legal_moves(*args)
      moves.delete_if { |move| into_check?(move) }
      moves
    end

    def pseudo_legal?(move)
      # Source square must not be vacant.
      piece = piece_type_at(move.from_square)
      unless piece
        return false
      end

      # Get square masks.
      from_mask = Board::BB_SQUARES[move.from_square]
      to_mask   = Board::BB_SQUARES[move.to_square]

      # Check turn.
      if !@occupied_co[turn] & from_mask != 0
        return false
      end

      # Destination square can not be occupied.
      if @occupied_co[turn] & to_mask != 0
        return false
      end

      # Only pawns can promote and only on the backrank.
      if move.promotion
        if piece != Board::PAWN
          return false
        end

        if @turn == Board::WHITE && rank_index(move.to_square) != 7
          return false
        elsif @turn == Board::BLACK && rank_index(move.to_square) != 0
          return false
        end
      end

      # Handle moves by piece type.
      if piece == Board::KING
          # Castling.
          if @turn == Board::WHITE && move.from_square == E1
            if move.to_square == Board::G1 && @castling_rights & Board::CASTLING_WHITE_KINGSIDE != 0 && !(Board::BB_F1 | Board::BB_G1) & occupied != 0
              if !attacked_by?(Board::BLACK, Board::E1) and not attacked_by?(Board::BLACK, Board::F1) and !attacked_by?(Board::BLACK, Board::G1)
                return true
              end
            elsif move.to_square == Board::C1 and castling_rights & Board::CASTLING_WHITE_QUEENSIDE and !(Board::BB_B1 | Board::BB_C1 | Board::BB_D1) & occupied != 0
              if !attacked_by?(Board::BLACK, Board::E1) and not attacked_by?(Board::BLACK, Board::D1) and !attacked_by?(Board::BLACK, Board::C1)
                return true
              end
            end
          elsif @turn == Board::BLACK and move.from_square == Board::E8
            if move.to_square == Board::G8 and castling_rights & Board::CASTLING_BLACK_KINGSIDE and !(Board::BB_F8 | Board::BB_G8) & occupied != 0
              if not attacked_by?(Board::WHITE, Board::E8) and not attacked_by?(Board::WHITE, Board::F8) and not attacked_by?(Board::WHITE, Board::G8)
                return true
              end
            elsif move.to_square == Board::C8 and castling_rights & Board::CASTLING_BLACK_QUEENSIDE and !(Board::BB_B8 | Board::BB_C8 | Board::BB_D8) & occupied != 0
              if not attacked_by?(Board::WHITE, Board::E8) and not attacked_by?(Board::WHITE, Board::D8) and not attacked_by?(Board::WHITE, Board::C8)
                return true
              end
            end
          end

          return king_attacks_from(move.from_square) & to_mask != 0
      elsif piece == Board::PAWN
        # Require promotion type if on promotion rank.
        if !move.promotion
          if turn == Board::WHITE and rank_index(move.to_square) == 7
            return false
          end
          if turn == Board::BLACK and rank_index(move.to_square) == 0
            return false
          end
        end

        return pawn_moves_from(move.from_square) & to_mask != 0
      elsif piece == Board::QUEEN
        return queen_attacks_from(move.from_square) & to_mask != 0
      elsif piece == Board::ROOK
        return rook_attacks_from(move.from_square) & to_mask != 0
      elsif piece == Board::BISHOP
        return bishop_attacks_from(move.from_square) & to_mask != 0
      elsif piece == Board::KNIGHT
        return knight_attacks_from(move.from_square) & to_mask != 0
      end
    end

    def generate_pseudo_legal_moves(castling: true, pawns: true, knights: true, bishops: true, rooks: true, queens: true, king: true)

      moves = []
      moves.push(*generate_white_moves(castling: castling, pawns: pawns)) if turn == Board::WHITE
      moves.push(*generate_black_moves(castling: castling, pawns: pawns)) if turn == Board::BLACK
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
      if castling_rights & Board::CASTLING_WHITE_KINGSIDE and not (Board::BB_F1 | Board::BB_G1) & occupied != 0
        if not attacked_by?(Board::BLACK, Board::E1) and not attacked_by?(Board::BLACK, Board::F1) and not attacked_by?(Board::BLACK, Board::G1)
          moves << Move.new(Board::E1, Board::G1)
        end
      end

      # Castling long.
      if castling_rights & Board::CASTLING_WHITE_QUEENSIDE and not (Board::BB_B1 | Board::BB_C1 | Board::BB_D1) & occupied_l45 != 0
        if not attacked_by?(Board::BLACK, Board::C1) and not attacked_by?(Board::BLACK, Board::D1) and not attacked_by?(Board::BLACK, Board::E1)
          moves << Move.new(Board::E1, Board::C1)
        end
      end

      moves
    end

    def generate_white_pawn_moves
      ret_moves = []
      # En-passant moves.
      movers = pawns & occupied_co[Board::WHITE]
      if ep_square
        moves = Board::BB_PAWN_ATTACKS[Board::BLACK][ep_square] & movers

        from_square = bit_scan(moves)
        while from_square do
          ret_moves << Move.new(from_square, ep_square)
          from_square = bit_scan(moves, from_square + 1)
        end
      end

      # Pawn captures.

      # Right
      moves = shift_up_right(movers) & occupied_co[Board::BLACK]
      to_square = bit_scan(moves)
      while to_square do
        from_square = to_square - 9
        if rank_index(to_square) != 7
          ret_moves << Move.new(from_square, to_square)
        else
          ret_moves << Move.new(from_square, to_square, Board::QUEEN)
          ret_moves << Move.new(from_square, to_square, Board::KNIGHT)
          ret_moves << Move.new(from_square, to_square, Board::ROOK)
          ret_moves << Move.new(from_square, to_square, Board::BISHOP)
        end
        to_square = bit_scan(moves, to_square + 1)
      end

      # Left
      moves = shift_up_left(movers) & occupied_co[Board::BLACK]
      to_square = bit_scan(moves)
      while to_square do
        from_square = to_square - 7
        if rank_index(to_square) != 7
          ret_moves << Move.new(from_square, to_square)
        else
          ret_moves << Move.new(from_square, to_square, Board::QUEEN)
          ret_moves << Move.new(from_square, to_square, Board::KNIGHT)
          ret_moves << Move.new(from_square, to_square, Board::ROOK)
          ret_moves << Move.new(from_square, to_square, Board::BISHOP)
        end
        to_square = bit_scan(moves, to_square + 1)
      end

      # Pawns one forward.
      moves = shift_up(movers) & ~occupied
      movers = moves
      to_square = bit_scan(moves)
      while to_square do
        from_square = to_square - 8
        if rank_index(to_square) != 7
          ret_moves << Move.new(from_square, to_square)
        else
          ret_moves << Move.new(from_square, to_square, Board::QUEEN)
          ret_moves << Move.new(from_square, to_square, Board::KNIGHT)
          ret_moves << Move.new(from_square, to_square, Board::ROOK)
          ret_moves << Move.new(from_square, to_square, Board::BISHOP)
        end
        to_square = bit_scan(moves, to_square + 1)
      end

      # Pawns two forward.
      moves = shift_up(movers) & Board::BB_RANK_4 & ~occupied
      to_square = bit_scan(moves)
      while to_square do
        from_square = to_square - 16
        ret_moves << Move.new(from_square, to_square)
        to_square = bit_scan(moves, to_square + 1)
      end

      ret_moves
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
      if castling_rights & Board::CASTLING_BLACK_KINGSIDE and not (Board::BB_F8 | Board::BB_G8) & occupied != 0
        if not attacked_by?(Board::WHITE, Board::E8) and not attacked_by?(Board::WHITE, Board::F8) and not attacked_by?(Board::WHITE, Board::G8)
          moves << Move.new(Board::E8, Board::G8)
        end
      end

      # Castling long.
      if castling_rights & Board::CASTLING_BLACK_QUEENSIDE and not (Board::BB_B8 | Board::BB_C8 | Board::BB_D8) & occupied != 0
        if not attacked_by?(Board::WHITE, Board::C8) and not attacked_by?(Board::WHITE, Board::D8) and not attacked_by?(Board::WHITE, Board::E8)
          moves << Move.new(Board::E8, Board::C8)
        end
      end

      moves
    end

    def generate_black_pawn_moves
      ret_moves = []
      # En-passant moves.
      movers = pawns & occupied_co[Board::BLACK]
      if ep_square
        moves = Board::BB_PAWN_ATTACKS[Board::WHITE][ep_square] & movers
        from_square = bit_scan(moves)
        while from_square do
          ret_moves << Move.new(from_square, ep_square)
          from_square = bit_scan(moves, from_square + 1)
        end
      end

      # Pawn captures.

      # Left
      moves = shift_down_left(movers) & occupied_co[Board::WHITE]
      to_square = bit_scan(moves)
      while to_square do
        from_square = to_square + 9
        if rank_index(to_square) != 0
          ret_moves << Move.new(from_square, to_square)
        else
          ret_moves << Move.new(from_square, to_square, Board::QUEEN)
          ret_moves << Move.new(from_square, to_square, Board::KNIGHT)
          ret_moves << Move.new(from_square, to_square, Board::ROOK)
          ret_moves << Move.new(from_square, to_square, Board::BISHOP)
        end
        to_square = bit_scan(moves, to_square + 1)
      end

      # Right
      moves = shift_down_right(movers) & occupied_co[Board::WHITE]
      to_square = bit_scan(moves)
      while to_square do
        from_square = to_square + 7
        if rank_index(to_square) != 0
          ret_moves << Move.new(from_square, to_square)
        else
          ret_moves << Move.new(from_square, to_square, Board::QUEEN)
          ret_moves << Move.new(from_square, to_square, Board::KNIGHT)
          ret_moves << Move.new(from_square, to_square, Board::ROOK)
          ret_moves << Move.new(from_square, to_square, Board::BISHOP)
        end
        to_square = bit_scan(moves, to_square + 1)
      end

      # Pawns one forward.
      moves     = shift_down(movers) & ~occupied
      movers    = moves
      to_square = bit_scan(moves)
      while to_square do
        from_square = to_square + 8
        if rank_index(to_square) != 0
          ret_moves << Move.new(from_square, to_square)
        else
          ret_moves << Move.new(from_square, to_square, Board::QUEEN)
          ret_moves << Move.new(from_square, to_square, Board::KNIGHT)
          ret_moves << Move.new(from_square, to_square, Board::ROOK)
          ret_moves << Move.new(from_square, to_square, Board::BISHOP)
        end
        to_square = bit_scan(moves, to_square + 1)
      end

      # Pawns two forward.
      moves     = shift_down(movers) & Board::BB_RANK_5 & ~occupied
      to_square = bit_scan(moves)
      while to_square do
        from_square = to_square + 16
        ret_moves << Move.new(from_square, to_square)
        to_square = bit_scan(moves, to_square + 1)
      end

      ret_moves
    end

    def generate_knight_moves
      ret_moves = []

      movers      = knights & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square do
        moves = knight_attacks_from(from_square) & ~occupied_co[turn]
        to_square = bit_scan(moves)
        while to_square do
          ret_moves << Move.new(from_square, to_square)
          to_square = bit_scan(moves, to_square + 1)
        end
        from_square = bit_scan(movers, from_square + 1)
      end

      ret_moves
    end

    def generate_bishop_moves
      ret_moves = []

      movers      = bishops & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square do
        moves = bishop_attacks_from(from_square) & ~occupied_co[turn]
        to_square = bit_scan(moves)
        while to_square do
          ret_moves << Move.new(from_square, to_square)
          to_square = bit_scan(moves, to_square + 1)
        end
        from_square = bit_scan(movers, from_square + 1)
      end

      ret_moves
    end

    def generate_rook_moves
      ret_moves = []

      movers      = rooks & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square do
        moves = rook_attacks_from(from_square) & ~occupied_co[turn]
        to_square = bit_scan(moves)
        while to_square do
          ret_moves << Move.new(from_square, to_square)
          to_square = bit_scan(moves, to_square + 1)
        end
        from_square = bit_scan(movers, from_square + 1)
      end

      ret_moves
    end

    def generate_queen_moves
      ret_moves = []

      movers      = queens & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square do
        moves = queen_attacks_from(from_square) & ~occupied_co[turn]
        to_square = bit_scan(moves)
        while to_square do
          ret_moves << Move.new(from_square, to_square)
          to_square = bit_scan(moves, to_square + 1)
        end
        from_square = bit_scan(movers, from_square + 1)
      end

      ret_moves
    end

    def generate_king_moves
      ret_moves = []

      from_square = king_squares[turn]
      moves       = king_attacks_from(from_square) & ~occupied_co[turn]
      to_square   = bit_scan(moves)

      while to_square do
        ret_moves << Move.new(from_square, to_square)
        to_square = bit_scan(moves, to_square + 1)
      end

      ret_moves
    end

    def pseudo_legal_move_count
      # In a way duplicates generate_pseudo_legal_moves() in order to use
      # population counts instead of counting actually yielded moves.
      count = 0

      if turn == Board::WHITE
        # Castling short.
        if castling_rights & Board::CASTLING_WHITE_KINGSIDE and not (Board::BB_F1 | Board::BB_G1) & occupied != 0
          if !attacked_by?(Board::BLACK, Board::E1) and !attacked_by?(Board::BLACK, Board::F1) and !attacked_by?(Board::BLACK, Board::G1)
            count += 1
          end
        end

        # Castling long.
        if castling_rights & Board::CASTLING_WHITE_QUEENSIDE and not (Board::BB_B1 | Board::BB_C1 | Board::BB_D1) & occupied != 0
          if !attacked_by?(Board::BLACK, Board::C1) and !attacked_by?(Board::BLACK, Board::D1) and !attacked_by?(Board::BLACK, Board::E1)
            count += 1
          end
        end

        # En-passant moves.
        movers = pawns & occupied_co[Board::WHITE]
        if ep_square
          moves  = Board::BB_PAWN_ATTACKS[Board::BLACK][ep_square] & movers
          count += pop_count(moves)
        end

        # Pawn captures.
        moves = shift_up_right(movers) & occupied_co[Board::BLACK]
        count += pop_count(moves & Board::BB_RANK_8) * 3
        count += pop_count(moves)

        moves  = shift_up_left(movers) & occupied_co[Board::BLACK]
        count += pop_count(moves & Board::BB_RANK_8) * 3
        count += pop_count(moves)

        # Pawns one forward.
        moves  = shift_up(movers) & ~occupied
        movers = moves
        count += pop_count(moves & Board::BB_RANK_8) * 3
        count += pop_count(moves)

        # Pawns two forward.
        moves  = shift_up(movers) & Board::BB_RANK_4 & ~occupied
        count += pop_count(moves)
      else
        # Castling short.
        if castling_rights & Board::CASTLING_BLACK_KINGSIDE and !(Board::BB_F8 | Board::BB_G8) & occupied != 0
          if !attacked_by?(Board::WHITE, Board::E8) and !attacked_by?(Board::WHITE, Board::F8) and !attacked_by?(Board::WHITE, Board::G8)
            count += 1
          end
        end

        # Castling long.
        if castling_rights & Board::CASTLING_BLACK_QUEENSIDE and !(Board::BB_B8 | Board::BB_C8 | Board::BB_D8) & occupied != 0
          if !attacked_by?(Board::WHITE, Board::C8) and !attacked_by?(Board::WHITE, Board::D8) and !attacked_by?(Board::WHITE, Board::E8)
            count += 1
          end
        end

        # En-passant moves.
        movers = pawns & occupied_co[Board::BLACK]
        if ep_square
          moves  = Board::BB_PAWN_ATTACKS[Board::WHITE][ep_square] & movers
          count += pop_count(moves)
        end

        # Pawn captures.
        moves  = shift_down_left(movers) & occupied_co[Board::WHITE]
        count += pop_count(moves & Board::BB_RANK_1) * 3
        count += pop_count(moves)

        moves  = shift_down_right(movers) & occupied_co[Board::WHITE]
        count += pop_count(moves & Board::BB_RANK_1) * 3
        count += pop_count(moves)

        # Pawns one forward.
        moves  = shift_down(movers) & ~occupied
        movers = moves
        count += pop_count(moves & Board::BB_RANK_1) * 3
        count += pop_count(moves)

        # Pawns two forward.
        moves  = shift_down(movers) & Board::BB_RANK_5 & ~occupied
        count += pop_count(moves)
      end

      # Knight moves.
      movers      = knights & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square do
        moves  = knight_attacks_from(from_square) & ~occupied_co[turn]
        count += pop_count(moves)
        from_square = bit_scan(movers, from_square + 1)
      end

      # Bishop moves.
      movers      = bishops & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square do
        moves  = bishop_attacks_from(from_square) & ~occupied_co[turn]
        count += pop_count(moves)
        from_square = bit_scan(movers, from_square + 1)
      end

      # Rook moves.
      movers = rooks & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square do
        moves  = rook_attacks_from(from_square) & ~occupied_co[turn]
        count += pop_count(moves)
        from_square = bit_scan(movers, from_square + 1)
      end

      # Queen moves.
      movers = queens & occupied_co[turn]
      from_square = bit_scan(movers)
      while from_square do
        moves  = queen_attacks_from(from_square) & ~occupied_co[turn]
        count += pop_count(moves)
        from_square = bit_scan(movers, from_square + 1)
      end

      # King moves.
      from_square = king_squares[turn]
      moves       = king_attacks_from(from_square) & ~occupied_co[turn]
      count      += pop_count(moves)

      count
    end

    def pawn_moves_from(square)
      targets = Board::BB_PAWN_F1[turn][square] & ~occupied

      if targets != 0
        targets |= Board::BB_PAWN_F2[turn][square] & ~occupied
      end

      if !ep_square && !(ep_square != 0)
        targets |= Board::BB_PAWN_ATTACKS[turn][square] & occupied_co[turn ^ 1]
      else
        targets |= Board::BB_PAWN_ATTACKS[turn][square] & (occupied_co[turn ^ 1] | Board::BB_SQUARES[ep_square])
      end

      targets
    end

    def knight_attacks_from(square)
      Board::BB_KNIGHT_ATTACKS[square]
    end

    def king_attacks_from(square)
      Board::BB_KING_ATTACKS[square]
    end

    def rook_attacks_from(square)
      return (Board::BB_RANK_ATTACKS[square][(occupied >> ((square & ~7) + 1)) & 63] |
              Board::BB_FILE_ATTACKS[square][(occupied_l90 >> (((square & 7) << 3) + 1)) & 63])
    end

    def bishop_attacks_from(square)
      val = (Board::BB_R45_ATTACKS[square][(occupied_r45 >> Board::BB_SHIFT_R45[square]) & 63] |
              Board::BB_L45_ATTACKS[square][(occupied_l45 >> Board::BB_SHIFT_L45[square]) & 63])

      return val
    end

    def queen_attacks_from(square)
      return rook_attacks_from(square) | bishop_attacks_from(square)
    end
  end
end
