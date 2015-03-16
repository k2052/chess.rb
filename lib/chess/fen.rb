module Chess
  module FEN
    def set_fen(fen)
      ###
      # Parses a FEN and sets the position from it.
      #
      # Rasies `ValueError` if the FEN string is invalid.
      ###

      # Ensure there are six parts.
      parts = fen.split()
      if parts.length != 6
        raise ValueError, "fen string should consist of 6 parts: #{repr(fen)}"
      end

      # Ensure the board part is valid.
      rows = parts[0].split("/")
      if rows.length != 8
        raise ValueError, "expected 8 rows in position part of fen: #{repr(fen)}"
      end

      # Validate each row.
      rows.each do |row|
        field_sum          = 0
        previous_was_digit = false

        row.each do |c|
          if ["1", "2", "3", "4", "5", "6", "7", "8"].include? c
            if previous_was_digit
              raise ValueError, "two subsequent digits in position part of fen: #{repr(fen)}"
            end
            field_sum         += c.to_i
            previous_was_digit = true
          elsif ["p", "n", "b", "r", "q", "k"].include? c.downcase
            field_sum += 1
            previous_was_digit = false
          else
            raise ValueError, "invalid character in position part of fen: #{repr(fen)}"
          end
        end

        if field_sum != 8
          raise ValueError, "expected 8 columns per row in position part of fen: #{repr(fen)}"
        end
      end

      # Check that the turn part is valid.
      unless ["w", "b"].include? parts[1]
        raise ValueError, "expected 'w' or 'b' for turn part of fen: #{repr(fen)}"
      end

      # Check that the castling part is valid.
      unless FEN_CASTLING_REGEX.match(parts[2])
        raise ValueError, "invalid castling part in fen: #{repr(fen)}"
      end

      # Check that the en-passant part is valid.
      if parts[3] != "-"
        if parts[1] == "w"
          if rank_index(SQUARE_NAMES.index(parts[3])) != 5
            raise ValueError, "expected en-passant square to be on sixth rank: #{repr(fen)}"
          else
            if rank_index(SQUARE_NAMES.index(parts[3])) != 2
              raise ValueError, "expected en-passant square to be on third rank: #{repr(fen)}"
            end
          end
        end
      end

      # Check that the half move part is valid.
      if parts[4].to_i < 0
        raise ValueError, "halfmove clock can not be negative: #{repr(fen)}"
      end

      # Check that the fullmove number part is valid.
      # 0 is allowed for compability but later replaced with 1.
      if parts[5].to_i < 0
        raise ValueError, "fullmove number must be positive: #{repr(fen)}"
      end

      # Clear board.
      clear()

      # Put pieces on the board.
      square_index = 0
      parts[0].each do |c|
        if ["1", "2", "3", "4", "5", "6", "7", "8"].include? c
          square_index += c.to_i
        elsif ["p", "n", "b", "r", "q", "k"].include? c.downcase
          set_piece_at(SQUARES_180[square_index], Piece.from_symbol(c))
          square_index += 1
        end
      end

      # Set the turn.
      if parts[1] == "w"
        turn = WHITE
      else
        turn = BLACK
      end

      # Set castling flags.
      castling_rights = CASTLING_nil
      if parts[2].include? "K"
        castling_rights |= CASTLING_WHITE_KINGSIDE
      end

      if parts[2].include? "Q"
        castling_rights |= CASTLING_WHITE_QUEENSIDE
      end

      if parts[2].include? "k"
        castling_rights |= CASTLING_BLACK_KINGSIDE
      end

      if parts[2].include? 'q'
        castling_rights |= CASTLING_BLACK_QUEENSIDE
      end

      # Set the en-passant square.
      if parts[3] == "-"
        ep_square = 0
      else
        ep_square = SQUARE_NAMES.index(parts[3])
      end

      # Set the mover counters.
      halfmove_clock  = parts[4].to_i
      if parts[5].nil? or parts[5] == 0
        fullmove_number = 1
      else
        fullmove_number = parts[5]
      end

      # Reset the transposition table.
      transpositions = {zobrist_hash => 1}
    end

    def fen
      # Gets the FEN representation of the position
      fen = []

      # Position, turn, castling and en passant.
      fen.append(epd())

      # Half moves.
      fen.append(" ")
      fen.append(halfmove_clock)

      # Ply.
      fen.append(" ")
      fen.append(fullmove_number)

      return fen.join ''
    end
  end
end
