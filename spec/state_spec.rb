describe Chess::State do
  describe '#insufficient_material?' do
    it 'checks for insufficient matterial' do
      board = Chess::Board.new
      expect(board.insufficient_material?).to eq(false)

      # King vs. King + 2 bishops of the same color.
      board = Chess::Board.new("k1K1B1B1/8/8/8/8/8/8/8 w - - 7 32")
      expect(board.insufficient_material?).to eq(true)

      board = Chess::Board.new
      board.put(Chess::Board::B8, Chess::Piece.from_symbol('b'))
      board.put(Chess::Board::C8, Chess::Piece.from_symbol('b'))
      board.put(Chess::Board::D8, Chess::Piece.from_symbol('b'))
      expect(board.insufficient_material?).to eq(false)
    end
  end

  describe '#can_claim_threefold_repitition?' do
    it 'handles threefold repetition' do
      board = Chess::Board.new
      expect(board.can_claim_threefold_repitition?).to eq(false)
      board.push_san('Nf3')

      expect(board.can_claim_threefold_repitition?).to eq(false)
      board.push_san('Nf6')

      expect(board.can_claim_threefold_repitition?).to eq(false)
      board.push_san('Ng1')

      expect(board.can_claim_threefold_repitition?).to eq(false)
      board.push_san('Ng8')

      expect(board.can_claim_threefold_repitition?).to eq(false)
      board.push_san('Nf3')

      expect(board.can_claim_threefold_repitition?).to eq(false)
      board.push_san('Nf6')

      expect(board.can_claim_threefold_repitition?).to eq(false)
      board.push_san('Ng1')

      expect(board.can_claim_threefold_repitition?).to eq(true)
      board.push_san('Ng8')

      expect(board.can_claim_threefold_repitition?).to eq(true)

      board.push_san('e4')
      expect(board.can_claim_threefold_repitition?).to eq(false)

      board.undo
      expect(board.can_claim_threefold_repitition?).to eq(true)

      while !board.move_stack.empty? do
        board.undo
      end

      expect(board.can_claim_threefold_repitition?).to eq(false)
    end
  end

  describe '#fivefold_repitition?' do
    it 'handles fivefold repititions' do
      fen = "rnbq1rk1/ppp3pp/3bpn2/3p1p2/2PP4/2NBPN2/PP3PPP/R1BQK2R w KQ - 3 7"
      board = Chess::Board.new(fen)
      expect(board.game_over?).to eq(false) # TODO: Resolve Why This Needs To be Called First or Transpositions tables get screwed
      3.times do
        board.push_san('Be2')
        board.push_san('Be7')
        board.push_san('Bd3')
        board.push_san('Bd6')
      end

      expect(board.can_claim_threefold_repitition?).to eq(true)
      expect(board.fivefold_repitition?).to eq(false)
      expect(board.game_over?).to eq(false)

      1.times do
        board.push_san('Be2')
        board.push_san('Be7')
        board.push_san('Bd3')
        board.push_san('Bd6')
      end
      expect(board.fivefold_repitition?).to eq(false)
      expect(board.game_over?).to eq(false)

      1.times do
        board.push_san('Be2')
        board.push_san('Be7')
        board.push_san('Bd3')
        board.push_san('Bd6')
      end
      expect(board.fivefold_repitition?).to eq(true)
      expect(board.game_over?).to eq(true)
    end
  end
end
