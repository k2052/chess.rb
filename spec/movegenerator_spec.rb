describe Chess::MoveGeneration do
  let(:positions) do
    positions = [
      {fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        square: 'e2', verbose: false, moves: ['e3', 'e4']},
      {fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        square: 'e9', verbose: false, moves: []},  # invalid square
      {fen: 'rnbqk1nr/pppp1ppp/4p3/8/1b1P4/2N5/PPP1PPPP/R1BQKBNR w KQkq - 2 3',
        square: 'c3', verbose: false, moves: []},  # pinned piece
      {fen: '8/k7/8/8/8/8/7p/K7 b - - 0 1',
        square: 'h2', verbose: false, moves: ['h1=Q+', 'h1=R+', 'h1=B', 'h1=N']},  # promotion
      {fen: 'r1bq1rk1/1pp2ppp/p1np1n2/2b1p3/2B1P3/2NP1N2/PPPBQPPP/R3K2R w KQ - 0 8',
        square: 'e1', verbose: false, moves: ['Kf1', 'Kd1', 'O-O', 'O-O-O']},  # castling
      {fen: 'r1bq1rk1/1pp2ppp/p1np1n2/2b1p3/2B1P3/2NP1N2/PPPBQPPP/R3K2R w - - 0 8',
        square: 'e1', verbose: false, moves: ['Kf1', 'Kd1']},  # no castling
      {fen: '8/7K/8/8/1R6/k7/1R1p4/8 b - - 0 1',
        square: 'a3', verbose: false, moves: []},  # trapped king
      {fen: '8/7K/8/8/1R6/k7/1R1p4/8 b - - 0 1',
        square: 'd2', verbose: true,
        moves:
          [{color:'b', from:'d2', to:'d1', flags:'np', piece:'p', promotion:'q', san:'d1=Q'},
           {color:'b', from:'d2', to:'d1', flags:'np', piece:'p', promotion:'r', san:'d1=R'},
           {color:'b', from:'d2', to:'d1', flags:'np', piece:'p', promotion:'b', san:'d1=B'},
           {color:'b', from:'d2', to:'d1', flags:'np', piece:'p', promotion:'n', san:'d1=N'}]
      }, # verbose
      {fen: 'rnbqk2r/ppp1pp1p/5n1b/3p2pQ/1P2P3/B1N5/P1PP1PPP/R3KBNR b KQkq - 3 5',
        square: 'f1', verbose: true, moves: []},  # issue #30
    ]
  end

  describe '#moves' do
    let(:chess) { Chess::Board.new }
    it 'returns the correct moves' do
      chess = Chess::Board.new(positions[0][:fen])
      chess.moves.each do |move|
        puts move.piece.symbol + chess.algebraic(move.from) + '-' + chess.algebraic(move.to)
      end
    end
  end
end
