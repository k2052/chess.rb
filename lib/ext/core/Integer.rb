class Integer
  def zerofill(count)
    # zero fill right shift
    self >> count & (2**(32-count)-1)
  end

  def to_int32
    number = self
    # (1)(2)
    begin
      sign = number < 0 ? -1 : 1
      abs = number.abs
      return 0 if abs == 0 || abs == Float::INFINITY
    rescue
      return 0
    end

    pos_int = sign * abs.floor  # (3)
    int_32bit = pos_int % 2**32 # (4)

    # (5)
    return int_32bit - 2**32 if int_32bit >= 2**31
    int_32bit
  end

  def to_boolean
    !self.zero?
  end
end
