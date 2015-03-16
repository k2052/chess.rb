module Chess
  module State
    def attacked_by?(color, square)
      ###
      # Checks if the given side attacks the given square. Pinned pieces still
      # count as attackers.
      ###
      if BB_PAWN_ATTACKS[color ^ 1][square] & (pawns | bishops) & occupied_co[color]
        return true
      end

      if knight_attacks_from(square) & knights & occupied_co[color]
        return true
      end

      if bishop_attacks_from(square) & (bishops | queens) & occupied_co[color]
        return true
      end

      if rook_attacks_from(square) & (rooks | queens) & occupied_co[color]
        return true
      end

      if king_attacks_from(square) & (kings | queens) & occupied_co[color]
        return true
      end

      return false
    end

    def attacker_mask(color, square)
      attackers = BB_PAWN_ATTACKS[color ^ 1][square] & pawns
      attackers |= knight_attacks_from(square) & knights
      attackers |= bishop_attacks_from(square) & (bishops | queens)
      attackers |= rook_attacks_from(square) & (rooks | queens)
      attackers |= king_attacks_from(square) & kings
      return attackers & occupied_co[color]
    end

    def attackers(color, square)
      ###
      # Gets a set of attackers of the given color for the given square.
      #
      # Returns a set of squares.
      ###
      return SquareSet.new(attacker_mask(color, square))
    end

    def is_check
      # Checks if the current side to move is in check
      is_attacked_by(turn ^ 1, king_squares[turn])
    end

    def is_into_check(move)
      ###
      # Checks if the given move would move would leave the king in check or
      # put it into check.
      ###
      push(move)
      is_check = was_into_check()
      pop()
      return is_check
    end

    def was_into_check
      ###
      # Checks if the king of the other side is attacked. Such a position is not
      # valid and could only be reached by an illegal move.
      ###
      return is_attacked_by(turn, king_squares[turn ^ 1])
    end

    def is_game_over
      ###
      # Checks if the game is over due to checkmate, stalemate, insufficient
      # mating material, the seventyfive-move rule or fivefold repitition.
      ###
      # Seventyfive-move rule.
      if halfmove_clock >= 150
        return true
      end

      # Insufficient material.
      if is_insufficient_material()
        return true
      end

      # Insufficient material.
      if is_insufficient_material
        return true
      end

      # Stalemate or checkmate.
      return true if generate_legal_moves.empty?

      # Fivefold repitition.
      if is_fivefold_repitition()
        return true
      end

      return false
    end

    def is_checkmate
      # Checks if the current position is a checkmate
      unless is_check
        return false
      end

      moves = generate_legal_moves
      if !moves.empty?
        return false
      else
        return true
      end
    end

    def is_stalemate
      # Checks if the current position is a stalemate
      if is_check
        return false
      end

      if generate_legal_moves.empty?
        return false
      else
        return true
      end
    end

    def is_insufficient_material
      # Checks for a draw due to insufficient mating material
      # Enough material to mate.
      if pawns or rooks or queens
        return false
      end

      # A single knight or a single bishop.
      if pop_count(occupied) <= 3
        return true
      end

      # More than a single knight.
      if knights
        return false
      end

      # All bishops on the same color.
      if bishops & BB_DARK_SQUARES == 0
        return true
      elsif bishops & BB_LIGHT_SQUARES == 0
        return true
      else
        return false
      end
    end

    def is_seventyfive_moves
      #
      # Since the first of July 2014 a game is automatically drawn (without
      # a claim by one of the players) if the half move clock since a capture
      # or pawn move is equal to or grather than 150. Other means to end a game
      # take precedence.
      if halfmove_clock >= 150
        unless generate_legal_moves.empty?
          return true
        end
      end

      return false
    end

    def is_fivefold_repitition
      ###
      # Since the first of July 2014 a game is automatically drawn (without
      # a claim by one of the players) if a position occurs for the fifth time
      # on consecutive alternating moves.
      ###
      zobrist_hash = zobrist_hash()

      # A minimum amount of moves must have been played and the position
      # in question must have appeared at least five times.
      if move_stack.length < 16 or transpositions[zobrist_hash] < 5
        return false
      end

      switchyard = Hamster.deque

      4.times do
        # Go back two full moves, each.
        4.times do
          switchyard.append(pop())
        end

        # Check the position was the same before.
        if zobrist_hash() != zobrist_hash
          while switchyard do
            push(switchyard.pop())
          end
          return false
        end
      end

      while switchyard do
        push(switchyard.pop())
      end

      return true
    end

    def can_claim_draw
      ###
      # Checks if the side to move can claim a draw by the fifty-move rule or
      # by threefold repitition.
      ###
      return can_claim_fifty_moves() || can_claim_threefold_repitition()
    end

    def can_claim_fifty_moves
      ###
      # Draw by the fifty-move rule can be claimed once the clock of halfmoves
      # since the last capture or pawn move becomes equal or greater to 100
      # and the side to move still has a legal move they can make.
      ###
      # Fifty-move rule.
      if halfmove_clock >= 100
        unless generate_legal_moves.empty?
          return true
        end
      end

      return false
    end

    def can_claim_threefold_repitition
      ###
      # Draw by threefold repitition can be claimed if the position on the
      # board occured for the third time or if such a repitition is reached
      # with one of the possible legal moves.
      ###
      # Threefold repitition occured.
      if transpositions[zobrist_hash()] >= 3
        return true
      end

      # The next legal move is a threefold repitition.
      generate_pseudo_legal_moves.each do |move|
        push(move)

        if !was_into_check() && transpositions[zobrist_hash()] >= 3
          pop()
          return true
        end

        pop()
      end

      return false
    end


    def status
      ###
      # Gets a bitmask of possible problems with the position.
      # Move making, generation and validation are only guaranteed to work on
      # a completely valid board.
      ###
      errors = STATUS_VALID

      if !occupied_co[WHITE] & kings
        errors |= STATUS_NO_WHITE_KING
      end

      if !occupied_co[BLACK] & kings
        errors |= STATUS_NO_BLACK_KING
      end

      if pop_count(occupied & kings) > 2
        errors |= STATUS_TOO_MANY_KINGS
      end

      if pop_count(occupied_co[WHITE] & pawns) > 8
        errors |= STATUS_TOO_MANY_WHITE_PAWNS
      end

      if pop_count(occupied_co[BLACK] & pawns) > 8
        errors |= STATUS_TOO_MANY_BLACK_PAWNS
      end

      if pawns & (BB_RANK_1 | BB_RANK_8)
        errors |= STATUS_PAWNS_ON_BACKRANK
      end

      if pop_count(occupied_co[WHITE]) > 16
        errors |= STATUS_TOO_MANY_WHITE_PIECES
      end

      if pop_count(occupied_co[BLACK]) > 16
        errors |= STATUS_TOO_MANY_BLACK_PIECES
      end

      if castling_rights & CASTLING_WHITE
        if !king_squares[WHITE] == E1
          errors |= STATUS_BAD_CASTLING_RIGHTS
        end

        if castling_rights & CASTLING_WHITE_QUEENSIDE
          if !BB_A1 & occupied_co[WHITE] & rooks
            errors |= STATUS_BAD_CASTLING_RIGHTS
          end
        end

        if castling_rights & CASTLING_WHITE_KINGSIDE
          if !BB_H1 & occupied_co[WHITE] & rooks
            errors |= STATUS_BAD_CASTLING_RIGHTS
          end
        end
      end

      if castling_rights & CASTLING_BLACK
        if !king_squares[BLACK] == E8
          errors |= STATUS_BAD_CASTLING_RIGHTS
        end

        if castling_rights & CASTLING_BLACK_QUEENSIDE
          if !BB_A8 & occupied_co[BLACK] & rooks
            errors |= STATUS_BAD_CASTLING_RIGHTS
          end
        end

        if castling_rights & CASTLING_BLACK_KINGSIDE
          if !BB_H8 & occupied_co[BLACK] & rooks
            errors |= STATUS_BAD_CASTLING_RIGHTS
          end
        end
      end

      if ep_square
        if turn == WHITE
          ep_rank = 5
          pawn_mask = shift_down(BB_SQUARES[ep_square])
        else
          ep_rank = 2
          pawn_mask = shift_up(BB_SQUARES[ep_square])
        end

        # The en-passant square must be on the third or sixth rank.
        if rank_index(ep_square) != ep_rank
          errors |= STATUS_INVALID_EP_SQUARE
        end

        # The last move must have been a double pawn push, so there must
        # be a pawn of the correct color on the fourth or fifth rank.
        if !pawns & occupied_co[turn ^ 1] & pawn_mask
          errors |= STATUS_INVALID_EP_SQUARE
        end
      end

      if !errors & (STATUS_NO_WHITE_KING | STATUS_NO_BLACK_KING | STATUS_TOO_MANY_KINGS)
        if was_into_check()
          errors |= STATUS_OPPOSITE_CHECK
        end
      end

      return errors
    end
  end
end
