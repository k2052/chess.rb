module Chess
  module San
    def parse_san(san)
      ###
      # Uses the current position as the context to parse a move in standard
      # algebraic notation and return the corresponding move object.
      #
      # The returned move is guaranteed to be either legal or a null move.
      #
      # Raises `ValueError` if the SAN is invalid or ambigous.
      ###

      # Null moves.
      if san == "--"
        return Move.new
      end

      move = nil
      # Castling.
      if ["O-O", "O-O+", "O-O#"].include? san
        if turn == WHITE
          move = Move.new(E1, G1)
        else
          move = Move.new(E8, G8)
        end

        if kings & occupied_co[turn] & BB_SQUARES[move.from_square] and is_legal(move)
          return move
        else
          raise ValueError, "illegal san: #{repr(san)}"
        end
      elsif ["O-O-O", "O-O-O+", "O-O-O#"].include? san
        if turn == WHITE
          move = Move.new(E1, C1)
        else
          move = Move.new(E8, C8)
        end
        if kings & occupied_co[turn] & BB_SQUARES[move.from_square] and is_legal(move)
          return move
        else
          raise ValueError, "illegal san: #{repr(san)}"
        end
      end

      # Match normal moves.
      match = SAN_REGEX.match(san)
      unless match
        raise ValueError, "invalid san: #{repr(san)}"
      end

      # Get target square.
      to_square = SQUARE_NAMES.index(match[4])

      # Get the promotion type.
      if !match[5]
        promotion = nil
      else
        promotion = PIECE_SYMBOLS.index(match[5][1].downcase().to_sym)
      end

      # Filter by piece type.
      if match[1] == "N"
        moves = generate_pseudo_legal_moves(castling=false, false, knights=true,
                                            bishops=false, rooks=false, queens=false, king=false)
      elsif match[1] == "B"
        moves = generate_pseudo_legal_moves(castling=false, pawns=false, knights=false,
                                            bishops=true, rooks=false, queens=false, king=false)
      elsif match[1] == "K"
        moves = generate_pseudo_legal_moves(castling=false, pawns=false, knights=false,
                                            bishops=false, rooks=false, queens=false, king=true)
      elsif match[1] == "R"
        moves = generate_pseudo_legal_moves(castling=false, pawns=false, knights=false,
                                            bishops=false, rooks=true, queens=false, king=false)
      elsif match[1] == "Q"
        moves = generate_pseudo_legal_moves(castling=false, pawns=false, knights=false,
                                            bishops=false, rooks=false, queens=true, king=false)
      else
        moves = generate_pseudo_legal_moves(castling=false, pawns=true, knights=false,
                                            bishops=false, rooks=false, queens=false, king=false)
      end

      # Filter by source file.
      from_mask = BB_ALL
      if match[2]
        from_mask &= BB_FILES[FILE_NAMES.index(match[2])]
      end

      # Filter by source rank.
      if match[3]
        from_mask &= BB_RANKS[match[3].to_i - 1]
      end

      # Match legal moves.
      matched_move = nil

      moves.each do |move|
        if move.to_square != to_square
          next
        end

        if move.promotion != promotion
          next
        end

        if !BB_SQUARES[move.from_square] & from_mask
          next
        end

        if is_into_check(move)
          next
        end

        if matched_move
          raise ValueError, "ambiguous san: #{repr(san)}"
        end

        matched_move = move
      end

      if !matched_move
        raise ValueError, "illegal san: #{repr(san)}"
      end

      return matched_move
    end

    def push_san(san)
      ###
      # Parses a move in standard algebraic notation, makes the move and puts
      # it on the the move stack.
      #
      # Raises `ValueError` if neither legal nor a null move.
      #
      # Returns the move.
      ###
      move = parse_san(san)
      push(move)
      return move
    end

    def san(move)
      ###
      # Gets the standard algebraic notation of the given move in the context of
      # the current position.
      #
      # There is no validation. It is only guaranteed to work if the move is
      # legal or a null move.
      ###

      unless move
        # Null move.
        return "--"
      end

      piece = piece_type_at(move.from_square)
      en_passant = false

      # Castling.
      if piece == KING
        if move.from_square == E1
          if move.to_square == G1
            return "O-O"
          elsif move.to_square == C1
            return "O-O-O"
          end
        elsif move.from_square == E8
          if move.to_square == G8
            return "O-O"
          elsif move.to_square == C8
            return "O-O-O"
          end
        end
      end

      if piece == PAWN
        san = ""

        # Detect en-passant.
        if !BB_SQUARES[move.to_square] & occupied
          en_passant = [7, 9].include? (move.from_square - move.to_square).abs
        end
      else
        # Get ambigous move candidates.
        if piece == KNIGHT
          san = "N"
          others = knights & knight_attacks_from(move.to_square)
        elsif piece == BISHOP
          san = "B"
          others = bishops & bishop_attacks_from(move.to_square)
        elsif piece == ROOK
          san = "R"
          others = rooks & rook_attacks_from(move.to_square)
        elsif piece == QUEEN
          san = "Q"
          others = queens & queen_attacks_from(move.to_square)
        elsif piece == KING
          san = "K"
          others = kings & king_attacks_from(move.to_square)
        end

        others &= ~BB_SQUARES[move.from_square]
        others &= occupied_co[turn]

        # Remove illegal candidates.
        squares = others
        square = bit_scan(squares)
        while square != - 1 and square do
          if is_into_check(Move(square, move.to_square))
            others &= ~BB_SQUARES[square]
          end

          square = bit_scan(squares, square + 1)
        end

        # Disambiguate.
        if others
          row, column = false, false

          if others & BB_RANKS[rank_index(move.from_square)]
            column = true
          end

          if others & BB_FILES[file_index(move.from_square)]
            row = true
          else
            column = true
          end

          if column
            san += FILE_NAMES[file_index(move.from_square)]
          end

          if row
            san += str(rank_index(move.from_square) + 1)
          end
        end
      end

      # Captures.
      if BB_SQUARES[move.to_square] & occupied or en_passant
        if piece == PAWN
          san += FILE_NAMES[file_index(move.from_square)]
        end
        san += "x"
      end

      # Destination square.
      san += SQUARE_NAMES[move.to_square]

      # Promotion.
      if move.promotion
        san += "=" + PIECE_SYMBOLS[move.promotion].upper()
      end

      # Look ahead for check or checkmate.
      push(move)
      if is_check()
        if is_checkmate()
          san += "#"
        else
          san += "+"
        end
      end
      pop()

      return san
    end
  end
end
