require_relative 'bitops'
module Chess
  class SquareSet
    attr_accessor :mask
    include BitOps

    def initialize(mask)
      @mask = mask
    end

    def to_boolean
      return @mask.to_boolean
    end

    def ==(other)
      self.to_i == other.to_i
    end

    def !=(other)
      self.to_i != other.to_i
    end

    def length
      return pop_count(mask)
    end

    def each
      return enum_for(:each) unless block_given?

      square = bit_scan(mask)
      while square do
        yield square
        square = bit_scan(mask, square + 1)
      end
    end

    def include?(square)
      return (Board::BB_SQUARES[square] & self.mask).to_boolean
    end

    def <<(shift)
      return SquareSet.new((mask << shift) & Board::BB_ALL)
    end

    def >>(shift)
      return SquareSet.new(mask >> shift)
    end

    def &(other)
      return SquareSet.new(mask & other.mask) if other.respond_to? :mask
      return SquareSet.new(mask & other)
    end

    def ^(other)
      return SquareSet.new((self.mask ^ other.mask) & Board::BB_ALL) if other.respond_to? :mask
      return SquareSet.new((self.mask ^ other) & Board::BB_ALL)
    end

    def |(other)
      return SquareSet.new((self.mask | other.mask) & Board::BB_ALL) if other.respond_to? :mask
      return SquareSet.new((self.mask | other) & Board::BB_ALL)
    end

    def ilshift(shift)
      @mask = (@mask << shift & Board::BB_ALL)
      return self
    end

    def irshift(shift)
      self.mask = @mask >> shift
      return self
    end

    def and_eq(other)
      if other.respond_to? :mask
        self.mask = self.mask & other.mask
      else
        self.mask = self.mask & other
      end
      return self
    end

    def ixor(other)
      if other.respond_to? :mask
        self.mask = (self.mask ^ other.mask) & Board::BB_ALL
      else
        self.mask = (self.mask ^ other) & Board::BB_ALL
      end

      return self
    end

    def ior(other)
      if other.respond_to? :mask
        self.mask = (self.mask | other.mask) & Board::BB_ALL
      else
        self.mask = (self.mask | other) & Board::BB_ALL
      end
      return self
    end

    def ~
      return SquareSet.new(~self.mask & Board::BB_ALL)
    end

    def to_oct
      return self.mask.oct
    end

    def to_hex
      return self.mask.to_s(16)
    end

    def to_i
      return self.mask
    end

    def index
      return self.mask
    end

    def to_s
      builder = []

      Board::SQUARES_180.each do |square|
        _mask = Board::BB_SQUARES[square]

        if mask & _mask != 0
          builder.push("1")
        else
          builder.push('.')
        end

        if _mask & Board::BB_FILE_H != 0
          if square != Board::H1
            builder.push("\n")
          end
        else
          builder.push(" ")
        end
      end

      return builder.join ''
    end
  end
end
