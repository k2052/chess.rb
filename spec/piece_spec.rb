describe Chess::Piece do
  describe '.from_symbol' do
    context 'when passed a white knight symbol' do
      it 'returns a white knight' do
        white_knight = Chess::Piece.from_symbol('N')

        expect(white_knight.color).to eq(Chess::Board::WHITE)
        expect(white_knight.piece_type).to eq(Chess::Board::KNIGHT)
        expect(white_knight.symbol).to eq 'N'
      end
    end

    context 'when pass a black queen symbol' do
      it 'returns a black queen' do
        black_queen = Chess::Piece.from_symbol("q")

        expect(black_queen.color).to      eq(Chess::Board::BLACK)
        expect(black_queen.piece_type).to eq(Chess::Board::QUEEN)
        expect(black_queen.symbol).to eq 'q'
      end
    end
  end

  describe '==' do
    it 'handles equality' do
      a = Chess::Piece.new(Chess::Board::BISHOP, Chess::Board::WHITE)
      b = Chess::Piece.new(Chess::Board::KING,   Chess::Board::BLACK)
      c = Chess::Piece.new(Chess::Board::KING,   Chess::Board::WHITE)
      d1 = Chess::Piece.new(Chess::Board::BISHOP, Chess::Board::WHITE)
      d2 = Chess::Piece.new(Chess::Board::BISHOP, Chess::Board::WHITE)

      expect(a).to eq(d1)
      expect(d1).to eq(a)
      expect(d1).to eq(d2)

      expect(a).to_not eq(b)
      expect(b).to_not eq(c)
      expect(b).to_not eq(d1)
      expect(a).to_not eq(c)
    end
  end
end
