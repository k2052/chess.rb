describe Chess::SquareSet do
  describe '==' do
    it 'handles equality' do
      a1 = Chess::SquareSet.new(Chess::Board::BB_RANK_4)
      a2 = Chess::SquareSet.new(Chess::Board::BB_RANK_4)
      b1 = Chess::SquareSet.new(Chess::Board::BB_RANK_5 | Chess::Board::BB_RANK_6)
      b2 = Chess::SquareSet.new(Chess::Board::BB_RANK_5 | Chess::Board::BB_RANK_6)

      expect(a1).to eq(a2)
      expect(b1).to eq(b2)
      expect(a1 != a2).to eq(false)
      expect(b1 != b2).to eq(false)

      expect(a1).to_not eq(b1)
      expect(a2).to_not eq(b2)
      expect(a1 == b1).to eq(false)
      expect(a2 == b2).to eq(false)

      expect(Chess::SquareSet.new(Chess::Board::BB_ALL)).to eq(Chess::Board::BB_ALL)
      expect(Chess::Board::BB_ALL).to eq(Chess::SquareSet.new(Chess::Board::BB_ALL))
    end
  end

  describe 'to_s' do
    it 'returns a representation of squares' do
      expected = %{
. . . . . . . 1
. 1 . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
. . . . . . . .
1 1 1 1 1 1 1 1}

      bb = Chess::SquareSet.new(Chess::Board::BB_H8 | Chess::Board::BB_B7 | Chess::Board::BB_RANK_1)
      # expect(bb.to_s).to eq(expected)
    end
  end

  describe '#each' do
    it 'returns an array and yields' do
      mask = Chess::Board::BB_G7 | Chess::Board::BB_G8
      bb = Chess::SquareSet.new(mask)
      res = []
      bb.each { |sq| res << sq }
      expect(res).to eq([Chess::Board::G7, Chess::Board::G8])
    end
  end

  describe '#&' do
    it '&s them' do
      expect(Chess::SquareSet.new(Chess::Board::BB_RANK_2) & Chess::Board::BB_FILE_D).to eq(Chess::Board::BB_D2)
    end
  end

  describe '#^' do
    it '^s them' do
      expect(Chess::SquareSet.new(Chess::Board::BB_ALL) ^ Chess::Board::BB_VOID).to eq(Chess::Board::BB_ALL)
    end
  end

  describe '#|' do
    it '|s them' do
      expect(Chess::SquareSet.new(Chess::Board::BB_C1) | Chess::Board::BB_FILE_C).to eq(Chess::Board::BB_FILE_C)
    end
  end

  describe '#ixor' do
    it 'ixors them' do
      bb = Chess::SquareSet.new(Chess::Board::BB_VOID)
      bb.ixor(Chess::Board::BB_ALL)
      expect(bb).to eq(Chess::Board::BB_ALL)
    end
  end

  describe '#and_eq' do
    it 'and_eqs them' do
      bb = Chess::SquareSet.new(Chess::Board::BB_ALL)
      bb.and_eq(Chess::Board::BB_E4)
      expect(bb).to eq(Chess::Board::BB_E4)
    end
  end

  describe '#ior' do
    it "ior's them" do
      bb = Chess::SquareSet.new(Chess::Board::BB_E4)
      bb.ior(Chess::Board::BB_RANK_4)
      expect(bb).to eq(Chess::Board::BB_RANK_4)
    end
  end

  describe '#<<' do
    it 'left shifts' do
      expect(Chess::SquareSet.new(Chess::Board::BB_F3) << 1).to eq(Chess::Board::BB_G3)
    end
  end

  describe '#>>' do
    it 'right shifts' do
      expect(Chess::SquareSet.new(Chess::Board::BB_C8) >> 2).to eq(Chess::Board::BB_A8)
    end
  end

  describe '#ilshift' do
    it 'ilshifts' do
      bb = Chess::SquareSet.new(Chess::Board::BB_D1)
      bb.ilshift(1)
      expect(bb).to eq(Chess::Board::BB_E1)
    end
  end

  describe '#irshift' do
    it 'irshifts' do
      bb = Chess::SquareSet.new(Chess::Board::BB_E1)
      bb.irshift(2)
      expect(bb).to eq(Chess::Board::BB_C1)
    end
  end
end
