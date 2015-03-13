describe Chess::Piece do
  describe '.new' do
    context 'when valid' do
      it 'returns a new instance' do
        expect(Chess::Piece.new(type: 'p', color: 'w')).to be_a Chess::Piece
      end
    end

    context 'when invalid' do
      it 'throws an error' do
        expect { Chess::Piece.new }.to raise_error
      end
    end
  end
end
