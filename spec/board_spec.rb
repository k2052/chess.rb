describe Chess::Board do
  describe '#put' do
    context 'valid bunch of pieces' do
      let(:chess) { Chess::Board.new }
      let(:pieces) do
        {
          a7: Chess::Piece.new(type: Chess::Board::PAWN,   color: Chess::Board::WHITE),
          b7: Chess::Piece.new(type: Chess::Board::PAWN,   color: Chess::Board::BLACK),
          c7: Chess::Piece.new(type: Chess::Board::KNIGHT, color: Chess::Board::WHITE),
          d7: Chess::Piece.new(type: Chess::Board::KNIGHT, color: Chess::Board::BLACK),
          e7: Chess::Piece.new(type: Chess::Board::BISHOP, color: Chess::Board::WHITE),
          f7: Chess::Piece.new(type: Chess::Board::BISHOP, color: Chess::Board::BLACK),
          g7: Chess::Piece.new(type: Chess::Board::ROOK,   color: Chess::Board::WHITE),
          h7: Chess::Piece.new(type: Chess::Board::ROOK,   color: Chess::Board::BLACK),
          a6: Chess::Piece.new(type: Chess::Board::QUEEN,  color: Chess::Board::WHITE),
          b6: Chess::Piece.new(type: Chess::Board::QUEEN,  color: Chess::Board::BLACK),
          a4: Chess::Piece.new(type: Chess::Board::KING,   color: Chess::Board::WHITE),
          h4: Chess::Piece.new(type: Chess::Board::KING,   color: Chess::Board::BLACK)
        }
      end

      it 'puts them all' do
        pieces.keys.each do |square|
          expect(chess.put(pieces[square], square)).to eq(true)
          expect(chess.get(square)).to eq(pieces[square])
        end
      end
    end

    context 'when we try to put two black kings' do
      let(:chess) { Chess::Board.new }
      let(:pieces) do
        {
          a7: Chess::Piece.new(type: Chess::Board::KING, color: Chess::Board::BLACK),
          h2: Chess::Piece.new(type: Chess::Board::KING, color: Chess::Board::WHITE),
          a8: Chess::Piece.new(type: Chess::Board::KING, color: Chess::Board::BLACK)
        }
      end

      it 'disallows them' do
        expect(chess.put(pieces[:a7], :a7)).to eq(true)
        expect(chess.put(pieces[:h2], :h2)).to eq(true)
        expect(chess.put(pieces[:a8], :a8)).to eq(false)
      end
    end

    context 'when we try to put two kings on the same square' do
      let(:chess) { Chess::Board.new }
      let(:pieces) do
        {
          a7: Chess::Piece.new(type: Chess::Board::KING, color: Chess::Board::BLACK),
          h1: Chess::Piece.new(type: Chess::Board::KING, color: Chess::Board::WHITE),
          h1: Chess::Piece.new(type: Chess::Board::KING, color: Chess::Board::WHITE)
        }
      end

      it 'allows it' do
        expect(chess.put(pieces[:a7], :a7)).to eq(true)
        expect(chess.put(pieces[:h1], :h1)).to eq(true)
        expect(chess.put(pieces[:h1], :h1)).to eq(true)
      end
    end
  end

  describe '#get' do
    context 'when a piece exists' do
      it 'returns the piece' do
      end
    end

    context 'when the piece does not exist' do
      it 'returns nil' do
      end
    end
  end

  describe '#move' do
    context 'legal move' do
      let(:moves) do
        [
          {fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
           legal: true,
           move: 'e4',
           next: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1'},
          {fen: '7k/3R4/3p2Q1/6Q1/2N1N3/8/8/3R3K w - - 0 1',
           legal: true,
           move: 'Rd8#',
           next: '3R3k/8/3p2Q1/6Q1/2N1N3/8/8/3R3K b - - 1 1'},
          {fen: 'rnbqkbnr/pp3ppp/2pp4/4pP2/4P3/8/PPPP2PP/RNBQKBNR w KQkq e6 0 1',
           legal: true,
           move: 'fxe6',
           next: 'rnbqkbnr/pp3ppp/2ppP3/8/4P3/8/PPPP2PP/RNBQKBNR b KQkq - 0 1',
           captured: 'p'},
          {fen: 'rnbqkbnr/pppp2pp/8/4p3/4Pp2/2PP4/PP3PPP/RNBQKBNR b KQkq e3 0 1',
           legal: true,
           move: 'fxe3',
           next: 'rnbqkbnr/pppp2pp/8/4p3/8/2PPp3/PP3PPP/RNBQKBNR w KQkq - 0 2',
           captured: 'p'}
        ]
      end

      it 'makes the move' do
        chess = Chess::Board.new(fen: moves[1][:fen])
        puts chess.board.inspect
      end
    end

    context 'illegal move' do
      let(:moves) do
        [
          {fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          legal: false,
          move: 'e5'}
        ]
      end

#      it 'raises an error' do
#        moves.each do |move|
#          chess = Chess::Board.new(fen: move[:fen])
#          expect { chess.move(move[:move]) }.to raise_error
#          expect(chess.fen).to not_eq(move[:fen])
#        end
#      end
    end
  end
end
