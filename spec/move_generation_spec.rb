describe Chess::MoveGeneration do
  describe '#generate_pseudo_legal_moves' do
    it 'generates pawn moves' do
      board = Chess::Board.new("8/2R1P3/8/2pp4/2k1r3/P7/8/1K6 w - - 1 55")
      moves = board.generate_pseudo_legal_moves
      expect(moves.length).to eq(16)
    end
  end
end
