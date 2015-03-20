module Chess
  module BitOps
    def pop_count(b)
      return b.to_s.count("1")
    end

    def bit_scan(b, n = 0)
      string = b.to_s(2)
      l = string.length
      string = string.slice(0, l - n)
      r = string.rindex('1')
      if r.nil?
        return nil
      else
        return l - r - 1
      end
    end

    def shift_down(b)
      b >> 8
    end

    def shift_2_down(b)
      b >> 16
    end

    def shift_up(b)
      (b << 8) & Board::BB_ALL
    end

    def shift_2_up(b)
      (b << 16) & Board::BB_ALL
    end

    def shift_right(b)
      (b << 1) & ~Board::BB_FILE_A
    end

    def shift_2_right(b)
      (b << 2) & ~Board::BB_FILE_A & ~Board::BB_FILE_B
    end

    def shift_left(b)
      (b >> 1) & ~Board::BB_FILE_H
    end

    def shift_2_left(b)
      (b >> 2) & ~Board::BB_FILE_G & ~Board::BB_FILE_H
    end

    def shift_up_left(b)
      (b << 7) & ~Board::BB_FILE_H
    end

    def shift_up_right(b)
      (b << 9) & ~Board::BB_FILE_A
    end

    def shift_down_left(b)
      (b >> 9) & ~Board::BB_FILE_H
    end

    def shift_down_right(b)
      (b >> 7) & ~Board::BB_FILE_A
    end

    def l90(b)
      mask = Board::BB_VOID

      square = bit_scan(b)
      while square do
        mask |= Board::BB_SQUARES_L90[square]
        square = bit_scan(b, square + 1)
      end

      return mask
    end

    def r45(b)
      mask = Board::BB_VOID

      square = bit_scan(b)
      while square do
        mask |= Board::BB_SQUARES_R45[square]
        square = bit_scan(b, square + 1)
      end

      return mask
    end

    def l45(b)
      mask = Board::BB_VOID

      square = bit_scan(b)
      while square do
        mask |= Board::BB_SQUARES_L45[square]
        square = bit_scan(b, square + 1)
      end

      return mask
    end
  end
end
