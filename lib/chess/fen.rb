module Chess
  class Fen
    def self.valid?(fen)
      validate(fen)[:valid]
    end

    def self.validate(fen)
      errors = [
        'No errors',
        'FEN string must contain six space-delimited fields',
        '6th field (move number) must be a positive integer',
        '5th field (half move counter) must be a non-negative integer.',
        '4th field (en-passant square) is invalid.',
        '3rd field (castling availability) is invalid.',
        '2nd field (side to move) is invalid.',
        '1st field (piece positions) does not contain 8 \'/\'-delimited rows.',
        '1st field (piece positions) is invalid [consecutive numbers].',
        '1st field (piece positions) is invalid [invalid piece].',
        '1st field (piece positions) is invalid [row too large].'
      ]

      # 1st criterion: 6 space-seperated fields?
      tokens = fen.split(/\s+/)

      unless tokens.length == 6
        return { valid: false, error_number: 1, error: errors[1] }
      end

      # 2nd criterion: move number field is a integer value > 0?
      unless tokens[5].is_numeric? and tokens[5].to_i >= 0
        return { valid: false, error_number: 2, error: errors[2] }
      end

      # 3rd criterion: half move counter is an integer >= 0?
      unless tokens[4].is_numeric? and tokens[4].to_i >= 0
        return { valid: false, error_number: 3, error: errors[3] }
      end

      # 4th criterion: 4th field is a valid e.p.-string?
      unless /^(-|[abcdefgh][36])$/.match(tokens[3])
        return { valid: false, error_number: 4, error: errors[4] }
      end

      # 5th criterion: 3th field is a valid castle-string?
      unless /^(KQ?k?q?|Qk?q?|kq?|q|-)$/.match(tokens[2])
        return { valid: false, error_number: 5, error: errors[5] }
      end

      # 6th criterion: 2nd field is "w" (white) or "b" (black)?
      unless /^(w|b)$/.match(tokens[1])
        return { valid: false, error_number: 6, error: errors[6] }
      end

      # 7th criterion: 1st field contains 8 rows?
      rows = tokens[0].split('/')
      unless rows.length == 8
        return { valid: false, error_number: 7, error: errors[7] }
      end

      # 8th criterion: every row is valid?
      rows.each do |row|
        # check for right sum of fields AND not two numbers in succession
        sum_fields          = 0
        previous_was_number = false

        row.chars.each do |k|
          if k.is_numeric?
            if previous_was_number
              return { valid: false, error_number: 8, error: errors[8] }
            end

            sum_fields += k.to_i
            previous_was_number = true
          else
            unless /^[prnbqkPRNBQK]$/.match(k)
              return { valid: false, error_number: 9, error: errors[9] }
            end

            sum_fields += 1
            previous_was_number = false
          end
        end

        unless sum_fields == 8
          return { valid: false, error_number: 10, error: errors[10] }
        end
      end

      # everything's okay!
      return { valid: true, error_number: 0, error: errors[0] }
    end
  end
end
