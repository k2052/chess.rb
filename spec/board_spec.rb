describe Chess::Board do
  describe '#get' do
    it 'retrives a piece' do
      board = Chess::Board.new
      expect(board.get(Chess::Board::B1)).to eq(Chess::Piece.from_symbol('N'))
    end
  end

  describe '#put' do
    it 'sets a piece on a square' do
      board = Chess::Board.new()
      board.put(Chess::Board::E4, Chess::Piece.from_symbol('r'))
      expect(board.piece_type_at(Chess::Board::E4)).to eq(Chess::Board::ROOK)
    end
  end

  describe '#remove' do
    it 'removes a piece on a square' do
      board = Chess::Board.new
      board.remove(Chess::Board::E2)
      expect(board.get(Chess::Board::E2)).to be_nil
    end
  end
end
