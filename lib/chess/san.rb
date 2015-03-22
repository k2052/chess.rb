module Chess
  module San
    ###
    # Uses the current position as the context to parse a move in standard
    # algebraic notation and return the corresponding move object.
    #
    # The returned move is guaranteed to be either legal or a null move.
    #
    # Raises `ArgumentError` if the SAN is invalid or ambigous.
    ###
    def parse_san(san)
      # Null moves.
      if san == '--'
        return Move.new
      end

      move = nil
      # Castling.
      if ['O-O', 'O-O+', 'O-O#'].include? san
        if turn == WHITE
          move = Move.new(E1, G1)
        else
          move = Move.new(E8, G8)
        end

        if kings & occupied_co[turn] & Board::BB_SQUARES[move.from_square] and legal?(move)
          return move
        else
          raise ArgumentError, "illegal san: #{san}"
        end
      elsif ['O-O-O', 'O-O-O+', 'O-O-O#'].include? san
        if turn == WHITE
          move = Move.new(E1, C1)
        else
          move = Move.new(E8, C8)
        end
        if kings & occupied_co[turn] & Board::BB_SQUARES[move.from_square] and legal?(move)
          return move
        else
          raise ArgumentError, "illegal san: #{san}"
        end
      end

      # Match normal moves.
      match = Board::SAN_REGEX.match(san)
      unless match
        raise ArgumentError, "invalid san: #{san}"
      end

      # Get target square.
      to_square = Board::SQUARE_NAMES.index(match[4].to_sym)

      # Get the promotion type.
      if !match[5]
        promotion = nil
      else
        promotion = Board::PIECE_SYMBOLS.index(match[5][1].downcase().to_sym)
      end

      # Filter by piece type.
      if match[1] == 'N'
        moves = generate_pseudo_legal_moves(castling: false, pawns: false, knights: true,
                                            bishops: false, rooks: false, queens: false, king: false)
      elsif match[1] == 'B'
        moves = generate_pseudo_legal_moves(castling: false, pawns: false, knights: false,
                                            bishops: true, rooks: false, queens: false, king: false)
      elsif match[1] == 'K'
        moves = generate_pseudo_legal_moves(castling: false, pawns: false, knights: false,
                                            bishops: false, rooks: false, queens: false, king: true)
      elsif match[1] == 'R'
        moves = generate_pseudo_legal_moves(castling: false, pawns: false, knights: false,
                                            bishops: false, rooks: true, queens: false, king: false)
      elsif match[1] == 'Q'
        moves = generate_pseudo_legal_moves(castling: false, pawns: false, knights: false,
                                            bishops: false, rooks: false, queens: true, king: false)
      else
        moves = generate_pseudo_legal_moves(castling: false, pawns: true, knights: false,
                                            bishops: false, rooks: false, queens: false, king: false)
      end

      # Filter by source file.
      from_mask = Board::BB_ALL
      if match[2]
        from_mask = from_mask & Board::BB_FILES[Board::FILE_NAMES.index(match[2].to_sym)]
      end

      # Filter by source rank.
      if match[3]
        from_mask = from_mask & Board::BB_RANKS[match[3].to_i - 1]
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

        if Board::BB_SQUARES[move.from_square] & from_mask == 0
          next
        end

        if into_check?(move)
          next
        end

        if matched_move
          raise ArgumentError, "ambiguous san: #{san}"
        end

        matched_move = move
      end

      if !matched_move
        raise ArgumentError, "illegal san: #{san}"
      end

      return matched_move
    end

    ###
    # Parses a move in standard algebraic notation, makes the move and puts
    # it on the the move stack.
    #
    # Raises `ValueError` if neither legal nor a null move.
    #
    # Returns the move.
    ###
    def push_san(san)
      move = parse_san(san)
      move(move)
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
        return '--'
      end

      piece = piece_type_at(move.from_square)
      en_passant = false

      # Castling.
      if piece == KING
        if move.from_square == E1
          if move.to_square == G1
            return 'O-O'
          elsif move.to_square == C1
            return 'O-O-O'
          end
        elsif move.from_square == E8
          if move.to_square == G8
            return 'O-O'
          elsif move.to_square == C8
            return 'O-O-O'
          end
        end
      end

      if piece == PAWN
        san = ''

        # Detect en-passant.
        if !Board::BB_SQUARES[move.to_square] & occupied
          en_passant = [7, 9].include? (move.from_square - move.to_square).abs
        end
      else
        # Get ambigous move candidates.
        if piece == KNIGHT
          san    = 'N'
          others = knights & knight_attacks_from(move.to_square)
        elsif piece == BISHOP
          san    = 'B'
          others = bishops & bishop_attacks_from(move.to_square)
        elsif piece == ROOK
          san    = 'R'
          others = rooks & rook_attacks_from(move.to_square)
        elsif piece == QUEEN
          san    = 'Q'
          others = queens & queen_attacks_from(move.to_square)
        elsif piece == KING
          san    = 'K'
          others = kings & king_attacks_from(move.to_square)
        end

        others = others & ~Board::BB_SQUARES[move.from_square]
        others = otehrs & occupied_co[turn]

        # Remove illegal candidates.
        squares = others
        square  = bit_scan(squares)
        while square do
          if into_check?(Move.new(square, move.to_square))
            others = others & ~Board::BB_SQUARES[square]
          end

          square = bit_scan(squares, square + 1)
        end

        # Disambiguate.
        if others
          row, column = false, false

          if others & Board::BB_RANKS[rank_index(move.from_square)]
            column = true
          end

          if others & Board::BB_FILES[file_index(move.from_square)]
            row = true
          else
            column = true
          end

          if column
            san += Board::FILE_NAMES[file_index(move.from_square).to_sym]
          end

          if row
            san += rank_index(move.from_square) + 1
          end
        end
      end

      # Captures.
      if Board::BB_SQUARES[move.to_square] & occupied or en_passant
        if piece == PAWN
          san += Board::FILE_NAMES[file_index(move.from_square).to_sym]
        end
        san += 'x'
      end

      # Destination square.
      san += Board::SQUARE_NAMES[move.to_square]

      # Promotion.
      if move.promotion
        san += '=' + Board::PIECE_SYMBOLS[move.promotion].upper
      end

      # Look ahead for check or checkmate.
      move(move)

      if check?
        if checkmate?
          san += '#'
        else
          san += '+'
        end
      end

      undo

      return san
    end
  end
end
