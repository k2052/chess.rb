describe Chess::State do
  describe '#in_checkmate?' do
    let(:checkmates) do
      [
        '8/5r2/4K1q1/4p3/3k4/8/8/8 w - - 0 7',
        '4r2r/p6p/1pnN2p1/kQp5/3pPq2/3P4/PPP3PP/R5K1 b - - 0 2',
        'r3k2r/ppp2p1p/2n1p1p1/8/2B2P1q/2NPb1n1/PP4PP/R2Q3K w kq - 0 8',
        '8/6R1/pp1r3p/6p1/P3R1Pk/1P4P1/7K/8 b - - 0 4'
      ]
    end

    context 'in checkmate' do
      it 'retuns true' do
      end
    end

    context 'not in checkmate' do
      it 'returns false' do
      end
    end
  end

  describe '#in_stalemate?' do
    let(:positions) do
      [
        '1R6/8/8/8/8/8/7R/k6K b - - 0 1',
        '8/8/5k2/p4p1p/P4K1P/1r6/8/8 w - - 0 2'
      ]
    end

    context 'in stalemate' do
      it 'returns true' do
      end
    end

    context 'not in stalemate' do
      let:
      it 'returns false' do
      end
    end
  end

  describe '#insufficient_material?' do
    context 'insufficient material' do
      let(:positions) do
        [
          {fen: '8/8/8/8/8/8/8/k6K w - - 0 1', draw: true},
          {fen: '8/2N5/8/8/8/8/8/k6K w - - 0 1', draw: true},
          {fen: '8/2b5/8/8/8/8/8/k6K w - - 0 1', draw: true},
          {fen: '8/b7/3B4/8/8/8/8/k6K w - - 0 1', draw: true},
          {fen: '8/b1B1b1B1/1b1B1b1B/8/8/8/8/1k5K w - - 0 1', draw: true}
        ]
      end

      it 'returns true' do
        positions.each do |position|
          chess = Chess::Board.new(fen: position[:fen])
          expect(chess.insufficient_material?).to be_true
        end
      end
    end

    context 'sufficient material' do
      let(:positions) do
        [
          {fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', draw: false},
          {fen: '8/b7/B7/8/8/8/8/k6K w - - 0 1', draw: false},
          {fen: '8/bB2b1B1/1b1B1b1B/8/8/8/8/1k5K w - - 0 1', draw: false}
        ]
      end

      it 'returns false' do
        positions.each do |position|
          chess = Chess::Board.new(fen: position[:fen])
          expect(chess.insufficient_material?).to be_false
        end
      end
    end
  end

  describe '#in_threefold_repetition?' do
  end

  describe '#in_draw?' do
    let(:positions) do
      [
        {fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
         moves: ['Nf3', 'Nf6', 'Ng1', 'Ng8', 'Nf3', 'Nf6', 'Ng1', 'Ng8']},

        # Fischer - Petrosian, Buenos Aires, 1971
        {fen: '8/pp3p1k/2p2q1p/3r1P2/5R2/7P/P1P1QP2/7K b - - 2 30',
         moves: ['Qe5', 'Qh5', 'Qf6', 'Qe2', 'Re5', 'Qd3', 'Rd5', 'Qe2']}
      ]
    end

    context 'in three fold repetition' do
      it 'returns true' do
        positions.each do |position|
          chess = Chess::Board.new(fen: position[:fen])

          position[:moves].each do |move|
            chess.move(move)
          end

          expect(chess.in_threefold_repetition?).to be_true
        end
      end
    end

    context 'not in three fold repetition' do
      it 'returns false' do
        positions.each do |position|
          chess = Chess::Board.new(fen: position[:fen])
          expect(chess.in_threefold_repetition?).to be_true
        end
      end
    end
  end

  describe 'History' do
    let(:history_tests) do
      [
       {verbose: false,
        fen: '4q2k/2r1r3/4PR1p/p1p5/P1Bp1Q1P/1P6/6P1/6K1 b - - 4 41',
        moves: ['c4', 'e6', 'Nf3', 'd5', 'd4', 'Nf6', 'Nc3', 'Be7', 'Bg5', 'O-O', 'e3', 'h6',
                'Bh4', 'b6', 'cxd5', 'Nxd5', 'Bxe7', 'Qxe7', 'Nxd5', 'exd5', 'Rc1', 'Be6',
                'Qa4', 'c5', 'Qa3', 'Rc8', 'Bb5', 'a6', 'dxc5', 'bxc5', 'O-O', 'Ra7',
                'Be2', 'Nd7', 'Nd4', 'Qf8', 'Nxe6', 'fxe6', 'e4', 'd4', 'f4', 'Qe7',
                'e5', 'Rb8', 'Bc4', 'Kh8', 'Qh3', 'Nf8', 'b3', 'a5', 'f5', 'exf5',
                'Rxf5', 'Nh7', 'Rcf1', 'Qd8', 'Qg3', 'Re7', 'h4', 'Rbb7', 'e6', 'Rbc7',
                'Qe5', 'Qe8', 'a4', 'Qd8', 'R1f2', 'Qe8', 'R2f3', 'Qd8', 'Bd3', 'Qe8',
                'Qe4', 'Nf6', 'Rxf6', 'gxf6', 'Rxf6', 'Kg8', 'Bc4', 'Kh8', 'Qf4']},
       {verbose: true,
        fen: '4q2k/2r1r3/4PR1p/p1p5/P1Bp1Q1P/1P6/6P1/6K1 b - - 4 41',
        moves: [
          {color: 'w', from: 'c2', to: 'c4', flags: 'b', piece: 'p', san: 'c4'},
          {color: 'b', from: 'e7', to: 'e6', flags: 'n', piece: 'p', san: 'e6'},
          {color: 'w', from: 'g1', to: 'f3', flags: 'n', piece: 'n', san: 'Nf3'},
          {color: 'b', from: 'd7', to: 'd5', flags: 'b', piece: 'p', san: 'd5'},
          {color: 'w', from: 'd2', to: 'd4', flags: 'b', piece: 'p', san: 'd4'},
          {color: 'b', from: 'g8', to: 'f6', flags: 'n', piece: 'n', san: 'Nf6'},
          {color: 'w', from: 'b1', to: 'c3', flags: 'n', piece: 'n', san: 'Nc3'},
          {color: 'b', from: 'f8', to: 'e7', flags: 'n', piece: 'b', san: 'Be7'},
          {color: 'w', from: 'c1', to: 'g5', flags: 'n', piece: 'b', san: 'Bg5'},
          {color: 'b', from: 'e8', to: 'g8', flags: 'k', piece: 'k', san: 'O-O'},
          {color: 'w', from: 'e2', to: 'e3', flags: 'n', piece: 'p', san: 'e3'},
          {color: 'b', from: 'h7', to: 'h6', flags: 'n', piece: 'p', san: 'h6'},
          {color: 'w', from: 'g5', to: 'h4', flags: 'n', piece: 'b', san: 'Bh4'},
          {color: 'b', from: 'b7', to: 'b6', flags: 'n', piece: 'p', san: 'b6'},
          {color: 'w', from: 'c4', to: 'd5', flags: 'c', piece: 'p', captured: 'p', san: 'cxd5'},
          {color: 'b', from: 'f6', to: 'd5', flags: 'c', piece: 'n', captured: 'p', san: 'Nxd5'},
          {color: 'w', from: 'h4', to: 'e7', flags: 'c', piece: 'b', captured: 'b', san: 'Bxe7'},
          {color: 'b', from: 'd8', to: 'e7', flags: 'c', piece: 'q', captured: 'b', san: 'Qxe7'},
          {color: 'w', from: 'c3', to: 'd5', flags: 'c', piece: 'n', captured: 'n', san: 'Nxd5'},
          {color: 'b', from: 'e6', to: 'd5', flags: 'c', piece: 'p', captured: 'n', san: 'exd5'},
          {color: 'w', from: 'a1', to: 'c1', flags: 'n', piece: 'r', san: 'Rc1'},
          {color: 'b', from: 'c8', to: 'e6', flags: 'n', piece: 'b', san: 'Be6'},
          {color: 'w', from: 'd1', to: 'a4', flags: 'n', piece: 'q', san: 'Qa4'},
          {color: 'b', from: 'c7', to: 'c5', flags: 'b', piece: 'p', san: 'c5'},
          {color: 'w', from: 'a4', to: 'a3', flags: 'n', piece: 'q', san: 'Qa3'},
          {color: 'b', from: 'f8', to: 'c8', flags: 'n', piece: 'r', san: 'Rc8'},
          {color: 'w', from: 'f1', to: 'b5', flags: 'n', piece: 'b', san: 'Bb5'},
          {color: 'b', from: 'a7', to: 'a6', flags: 'n', piece: 'p', san: 'a6'},
          {color: 'w', from: 'd4', to: 'c5', flags: 'c', piece: 'p', captured: 'p', san: 'dxc5'},
          {color: 'b', from: 'b6', to: 'c5', flags: 'c', piece: 'p', captured: 'p', san: 'bxc5'},
          {color: 'w', from: 'e1', to: 'g1', flags: 'k', piece: 'k', san: 'O-O'},
          {color: 'b', from: 'a8', to: 'a7', flags: 'n', piece: 'r', san: 'Ra7'},
          {color: 'w', from: 'b5', to: 'e2', flags: 'n', piece: 'b', san: 'Be2'},
          {color: 'b', from: 'b8', to: 'd7', flags: 'n', piece: 'n', san: 'Nd7'},
          {color: 'w', from: 'f3', to: 'd4', flags: 'n', piece: 'n', san: 'Nd4'},
          {color: 'b', from: 'e7', to: 'f8', flags: 'n', piece: 'q', san: 'Qf8'},
          {color: 'w', from: 'd4', to: 'e6', flags: 'c', piece: 'n', captured: 'b', san: 'Nxe6'},
          {color: 'b', from: 'f7', to: 'e6', flags: 'c', piece: 'p', captured: 'n', san: 'fxe6'},
          {color: 'w', from: 'e3', to: 'e4', flags: 'n', piece: 'p', san: 'e4'},
          {color: 'b', from: 'd5', to: 'd4', flags: 'n', piece: 'p', san: 'd4'},
          {color: 'w', from: 'f2', to: 'f4', flags: 'b', piece: 'p', san: 'f4'},
          {color: 'b', from: 'f8', to: 'e7', flags: 'n', piece: 'q', san: 'Qe7'},
          {color: 'w', from: 'e4', to: 'e5', flags: 'n', piece: 'p', san: 'e5'},
          {color: 'b', from: 'c8', to: 'b8', flags: 'n', piece: 'r', san: 'Rb8'},
          {color: 'w', from: 'e2', to: 'c4', flags: 'n', piece: 'b', san: 'Bc4'},
          {color: 'b', from: 'g8', to: 'h8', flags: 'n', piece: 'k', san: 'Kh8'},
          {color: 'w', from: 'a3', to: 'h3', flags: 'n', piece: 'q', san: 'Qh3'},
          {color: 'b', from: 'd7', to: 'f8', flags: 'n', piece: 'n', san: 'Nf8'},
          {color: 'w', from: 'b2', to: 'b3', flags: 'n', piece: 'p', san: 'b3'},
          {color: 'b', from: 'a6', to: 'a5', flags: 'n', piece: 'p', san: 'a5'},
          {color: 'w', from: 'f4', to: 'f5', flags: 'n', piece: 'p', san: 'f5'},
          {color: 'b', from: 'e6', to: 'f5', flags: 'c', piece: 'p', captured: 'p', san: 'exf5'},
          {color: 'w', from: 'f1', to: 'f5', flags: 'c', piece: 'r', captured: 'p', san: 'Rxf5'},
          {color: 'b', from: 'f8', to: 'h7', flags: 'n', piece: 'n', san: 'Nh7'},
          {color: 'w', from: 'c1', to: 'f1', flags: 'n', piece: 'r', san: 'Rcf1'},
          {color: 'b', from: 'e7', to: 'd8', flags: 'n', piece: 'q', san: 'Qd8'},
          {color: 'w', from: 'h3', to: 'g3', flags: 'n', piece: 'q', san: 'Qg3'},
          {color: 'b', from: 'a7', to: 'e7', flags: 'n', piece: 'r', san: 'Re7'},
          {color: 'w', from: 'h2', to: 'h4', flags: 'b', piece: 'p', san: 'h4'},
          {color: 'b', from: 'b8', to: 'b7', flags: 'n', piece: 'r', san: 'Rbb7'},
          {color: 'w', from: 'e5', to: 'e6', flags: 'n', piece: 'p', san: 'e6'},
          {color: 'b', from: 'b7', to: 'c7', flags: 'n', piece: 'r', san: 'Rbc7'},
          {color: 'w', from: 'g3', to: 'e5', flags: 'n', piece: 'q', san: 'Qe5'},
          {color: 'b', from: 'd8', to: 'e8', flags: 'n', piece: 'q', san: 'Qe8'},
          {color: 'w', from: 'a2', to: 'a4', flags: 'b', piece: 'p', san: 'a4'},
          {color: 'b', from: 'e8', to: 'd8', flags: 'n', piece: 'q', san: 'Qd8'},
          {color: 'w', from: 'f1', to: 'f2', flags: 'n', piece: 'r', san: 'R1f2'},
          {color: 'b', from: 'd8', to: 'e8', flags: 'n', piece: 'q', san: 'Qe8'},
          {color: 'w', from: 'f2', to: 'f3', flags: 'n', piece: 'r', san: 'R2f3'},
          {color: 'b', from: 'e8', to: 'd8', flags: 'n', piece: 'q', san: 'Qd8'},
          {color: 'w', from: 'c4', to: 'd3', flags: 'n', piece: 'b', san: 'Bd3'},
          {color: 'b', from: 'd8', to: 'e8', flags: 'n', piece: 'q', san: 'Qe8'},
          {color: 'w', from: 'e5', to: 'e4', flags: 'n', piece: 'q', san: 'Qe4'},
          {color: 'b', from: 'h7', to: 'f6', flags: 'n', piece: 'n', san: 'Nf6'},
          {color: 'w', from: 'f5', to: 'f6', flags: 'c', piece: 'r', captured: 'n', san: 'Rxf6'},
          {color: 'b', from: 'g7', to: 'f6', flags: 'c', piece: 'p', captured: 'r', san: 'gxf6'},
          {color: 'w', from: 'f3', to: 'f6', flags: 'c', piece: 'r', captured: 'p', san: 'Rxf6'},
          {color: 'b', from: 'h8', to: 'g8', flags: 'n', piece: 'k', san: 'Kg8'},
          {color: 'w', from: 'd3', to: 'c4', flags: 'n', piece: 'b', san: 'Bc4'},
          {color: 'b', from: 'g8', to: 'h8', flags: 'n', piece: 'k', san: 'Kh8'},
          {color: 'w', from: 'e4', to: 'f4', flags: 'n', piece: 'q', san: 'Qf4'}],
        fen: '4q2k/2r1r3/4PR1p/p1p5/P1Bp1Q1P/1P6/6P1/6K1 b - - 4 41'}
      ]
    end

    it 'reflects the correct history' do
      history_tests.each do |history_test|
        chess = Chess::Board.new
        history_test[:moves].each do |move|
          chess.move(move)
        end

        expect(chess.fen).to eq(history_test[:fen])
        expect(chess.history().to eq(history_test[:moves])
      end
    end
  end
end
