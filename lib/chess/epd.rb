module Chess
  module EPD
    def set_epd(epd)
      ###
      # Parses the given EPD string and uses it to set the position.
      #
      # If present the `hmvc` and the `fmvn` are used to set the half move
      # clock and the fullmove number. Otherwise `0` and `1` are used.
      #
      # Returns a dictionary of parsed operations. Values can be strings,
      # integers, floats or move objects.
      #
      # Raises `ValueError` if the EPD string is invalid.
      ###

      # Split into 4 or 5 parts.
      parts = epd.strip.chomp(";").split(nil, 4)
      if parts.length < 4
        raise ValueError, "epd should consist of at least 4 parts: #{repr(epd)}"
      end

      operations = {}

      # Parse the operations.
      if parts.length > 4
        operation_part  = parts.pop()
        operation_part += ";"

        opcode     = ""
        operand    = ""
        in_operand = false
        in_quotes  = false
        escape     = false

        position = nil

        operation_part.each do |c|
          if !in_operand
            if c == ";"
              operations[opcode] = nil
              opcode = ""
            elsif c == " "
              if opcode
                in_operand = true
              end
            else
              opcode += c
            end
          else
            if c == "\""
              if !operand and !in_quotes
                in_quotes = true
              elsif escape
                operand += c
              end
            elsif c == "\\"
              if escape
                operand += c
              else
                escape = true
              end
            elsif c == "s"
              if escape
                operand += ";"
              else
                operand += c
              end
            elsif c == ";"
              if escape
                operand += "\\"
              end

              if in_quotes
                operations[opcode] = operand
              else
                begin
                    operations[opcode] = Integer operand
                rescue
                    begin
                      operations[opcode] = Float operand
                    rescue
                      unless position
                        position = Board.new(parts + ["0", "1"].join(' '))
                      end

                      operations[opcode] = position.parse_san(operand)
                    end
                  end
                end

              opcode     = ''
              operand    = ''
              in_operand = false
              in_quotes  = false
              escape     = false
            else
              operand += c
            end
          end
        end
      end

      # Create a full FEN and parse it.
      if operations.include? 'hmvc'
        parts << operations['hmvc'].to_s
      else
        parts << '0'
      end

      if operations.include? 'fmvn'
        parts << operations['fmvn'].to_s
      else
        parts << '1'
      end

      set_fen(parts.join(' '))

      return operations
    end

    def epd(operations)
      ###
      # Gets an EPD representation of the current position.
      #
      # EPD operations can be given as keyword arguments. Supported operands
      # are strings, integers, floats and moves. All other operands are
      # converted to strings.
      #
      # `hmvc` and `fmvc` are *not* included by default. You can use:
      #
      # >>> board.epd(hmvc=board.halfmove_clock, fmvc=board.fullmove_number)
      # 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - hmvc 0; fmvc 1;'
      ###
      epd   = []
      empty = 0

      # Position part.
      SQUARES_180.eacho do |square|
        piece = piece_at(square)

        if !piece
          empty += 1
        else
          if empty
            epd.push(empty.to_s)
            empty = 0
          end
          epd << piece.symbol()
        end

        if BB_SQUARES[square] & BB_FILE_H
          if empty
            epd << empty.to_s
            empty = 0
          end

          if square != H1
            epd << '/'
          end
        end
      end

      epd << " "

      # Side to move.
      if turn == WHITE
        epd.push("w")
      else
        epd.push("b")
      end

      epd.push(" ")

      # Castling rights.
      if !castling_rights
        epd.push("-")
      else
        if castling_rights & CASTLING_WHITE_KINGSIDE
          epd.push("K")
        end
        if castling_rights & CASTLING_WHITE_QUEENSIDE
          epd.push("Q")
        end
        if castling_rights & CASTLING_BLACK_KINGSIDE
          epd.push("k")
        end
        if castling_rights & CASTLING_BLACK_QUEENSIDE
          epd.push("q")
        end
      end

      epd.push(" ")

      # En-passant square.
      if ep_square
        epd.push(SQUARE_NAMES[ep_square])
      else
        epd.push("-")
      end

      # Append operations.
      operations.items.each do |opcode, operand|
        epd.push(" ")
        epd.push(opcode)

        if operand.include?("from_square") && operand.include?("to_square")
          # Append SAN for moves.
          epd.push(" ")
          epd.push(san(operand))
        elsif operand.is_numeric?
          # Append integer or float.
          epd.push(" ")
          epd.push(operand.to_s)
        elsif operand != nil
          # Append as escaped string.
          epd.push(" \"")
          epd.push(operand.to_s.gsub("\r", "").gsub("\n", " ").gsub("\\", "\\\\").gsub(";", "\\s"))
          epd.push("\"")
        end

        epd.push(";")
      end

      return epd.join('')
    end
  end
end
