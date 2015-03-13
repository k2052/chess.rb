describe Chess::Move do
  describe '.new' do
    it 'returns a new instance of Move' do
      #  expect(Chess::Move.new(from: 'e2', to: 'e4')).to be_a Chess::Move
    end
  end

  describe '.from_san' do
    it 'returns a new instance of Move' do
      expect(Chess::Move.from_san('e4', Chess::Board.new)).to be_a Chess::Move
    end
  end
end
