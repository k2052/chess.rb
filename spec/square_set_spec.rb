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
end
