describe Chess::Move do
  describe '.from_uci' do
    context 'when the string is a valid uci string' do
      it 'returns a new move instance' do
        expect(Chess::Move.from_uci('b5c7').to_uci).to eq('b5c7')
        expect(Chess::Move.from_uci("e7e8q").to_uci).to eq('e7e8q')
      end
    end
  end

  describe '#==' do
    let(:a)  {  Chess::Move.new(Chess::Board::A1, Chess::Board::A2) }
    let(:b)  {  Chess::Move.new(Chess::Board::A1, Chess::Board::A2) }
    let(:d1) {  Chess::Move.new(Chess::Board::A7, Chess::Board::H8) }
    let(:d2) {  Chess::Move.new(Chess::Board::A7, Chess::Board::H8) }

    context 'when moves are the same' do
      it 'returns true' do
        expect(a).to eq(b)
        expect(b).to eq(a)
        expect(d1).to eq(d2)
      end
    end

    context 'when moves are not the same' do
      it 'returns false' do
        expect(a).not_to eq(d1)
        expect(b).not_to eq(d1)
      end
    end
  end
end
