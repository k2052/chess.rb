module Chess
  module PGN
    def to_pgn(newline: '\n', max_width: 0)
      # using the specification from http://www.chessclub.com/help/PGN-spec
      # example for html usage: .pgn({ max_width: 72, newline_char: "<br />" })
      result        = []
      header_exists = false

      # add the PGN header headerrmation
      header.each_with_index do |header, i|
        # TODO: order of enumerated properties in header object is not
        # guaranteed, see ECMA-262 spec (section 12.6.4)
        result.push('[' + i + ' \"' + header[i] + '\"]' + newline)
        header_exists = true
      end

      if header_exists && !history.empty?
        result.push(newline)
      end

      # pop all of history onto reversed_history */
      reversed_history = []
      while !history.empty?
        reversed_history.push(undo_move())
      end

      moves           = []
      move_string     = ''
      pgn_move_number = 1

      # build the list of moves.  a move_string looks like: "3. e3 e6" */
      while !reversed_history.empty? do
        move = reversed_history.pop()

        # if the position started with black to move, start PGN with 1. ... */
        if pgn_move_number == 1 && move.color == 'b'
          move_string = '1. ...'
          pgn_move_number += 1
        elsif move.color == 'w'
          # store the previous generated move_string if we have one */
          unless move_string.blank?
            moves.push(move_string)
          end

          move_string = pgn_move_number + '.'
          pgn_move_number += 1
        end

        move_string = move_string + ' ' + move_to_san(move)
        make_move(move)
      end

      # are there any other leftover moves? */
      unless move_string.blank?
        moves.push(move_string)
      end

      # is there a result? */
      if header['Result']
        moves.push(header['Result'])
      end

      # history should be back to what is was before we started generating PGN,
      # so join together moves
      if max_width == 0
        return result.join('') + moves.join(' ')
      end

      # wrap the PGN output at max_width */
      current_width = 0

      i = 0
      while i < moves.length do
        # if the current move will push past max_width */
        if current_width + moves[i].length > max_width && i != 0
          # don't end the line with whitespace */
          if result[result.length - 1] == ' '
            result.pop()
          end

          result.push(newline)
          current_width = 0
        elsif i != 0
          result.push(' ')
          current_width += 1
        end

        result.push(moves[i])
        current_width += moves[i].length

        i += 1
      end

      return result.join('')
    end

    def get_move_obj(move)
      return Move.from_san(move, board: self)
    end

    def parse_pgn_header(header, newline_char: '\r?\n')
      header_obj = {}
      headers    = header.split(RegExp.new(newline_char.mask))
      key        = ''
      value      = ''

      headers.each_with_index do |_header, i|
        key   = headers[i].gsub(/^\[([A-Z][A-Za-z]*)\s.*\]$/,  '')
        value = headers[i].gsub(/^\[[A-Za-z]+\s"(.*)"\]$/,     '')
        unless key.trim.blank?
          header_obj[key] = value
        end
      end

      return header_obj
    end

    def load_pgn(newline_char: '\r?\n')
      regex = RegExp.new('^(\\[(.|' + newline_char.mask  + ')*\\])' +
                             '('    + newline_char.mask  + ')*' +
                             '1.('  + newline_char.mask  + '|.)*$', 'g')

      # get header part of the PGN file */
      header_string = pgn.gsub(regex, '')

      # no info part given, begins with moves */
      if header_string[0] == '['
        header_string = ''
      end

      reset

      # parse PGN header */
      headers = parse_pgn_header(header_string, newline_char: newline_char)

      header.each do |key|
        set_header([key, headers[key]])
      end

      # delete header to get the moves
      ms = pgn.gsub(header_string, '').gsub(RegExp.new(newline_char.mask, 'g'), ' ')

      # delete comments
      ms = ms.gsub(/(\{[^}]+\})+?/, '')

      # delete move numbers
      ms = ms.gsub(/\d+\./, '')

      # trim and get array of moves
      moves = trim(ms).split(RegExp.new(/\s+/))

      # delete empty entries
      moves = moves.join(',').gsub(/,,+/, ',').split(',')
      move  = ''

      half_move = 0
      while half_move < moves.length - 1 do
        move = get_move_obj(moves[half_move])

        # move not possible! (don't clear the board to examine to show the latest valid position)
        if move.nil?
          return false
        else
          make_move(move)
        end
      end

      # examine last move
      move = moves[moves.length - 1]
      if Board::POSSIBLE_RESULTS.include?(move)
        if header['Result'].nil?
          set_header(['Result', move])
        end
      else
        move = get_move_obj(move)
        if move.nil?
          return false
        else
          make_move(move)
        end
      end

      return true
    end
  end
end
