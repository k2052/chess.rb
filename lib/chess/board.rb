require_relative 'move'
require_relative 'square_set'
require_relative 'bitops'
require_relative 'constants'
require_relative 'epd'
require_relative 'fen'
require_relative 'move_generation'
require_relative 'san'
require_relative 'state'
require_relative 'zobrist'

module Chess
  class Board
    include BitOps
    include EPD
    include FEN
    include MoveGeneration
    include San
    include State
    include Zobrist

    def self.file_index(square)
      # Gets the file index of square where `0` is the a file
      return square & 7
    end

    def self.rank_index(square)
      # Gets the rank index of the square where `0` is the first rank
      return square >> 3
    end

    WHITE  = 0
    BLACK  = 1
    COLORS = [WHITE, BLACK]
    NONE, PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING = *(0..7)
    PIECE_TYPES = [NONE, PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING]
    PIECE_SYMBOLS = ['', :p, :n, :b, :r, :q, :k]
    FILE_NAMES = [:a, :b, :c, :d, :e, :f, :g, :h]

    STARTING_FEN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'

    STATUS_VALID                 = 0
    STATUS_NO_WHITE_KING         = 1
    STATUS_NO_BLACK_KING         = 2
    STATUS_TOO_MANY_KINGS        = 4
    STATUS_TOO_MANY_WHITE_PAWNS  = 8
    STATUS_TOO_MANY_BLACK_PAWNS  = 16
    STATUS_PAWNS_ON_BACKRANK     = 32
    STATUS_TOO_MANY_WHITE_PIECES = 64
    STATUS_TOO_MANY_BLACK_PIECES = 128
    STATUS_BAD_CASTLING_RIGHTS   = 256
    STATUS_INVALID_EP_SQUARE     = 512
    STATUS_OPPOSITE_CHECK        = 1024

    SAN_REGEX = /^([NBKRQ])?([a-h])?([1-8])?x?([a-h][1-8])(=[nbrqNBRQ])?(\\+|#)?$/

    FEN_CASTLING_REGEX = /^(KQ?k?q?|Qk?q?|kq?|q|-)$/

    A1, B1, C1, D1, E1, F1, G1, H1,
    A2, B2, C2, D2, E2, F2, G2, H2,
    A3, B3, C3, D3, E3, F3, G3, H3,
    A4, B4, C4, D4, E4, F4, G4, H4,
    A5, B5, C5, D5, E5, F5, G5, H5,
    A6, B6, C6, D6, E6, F6, G6, H6,
    A7, B7, C7, D7, E7, F7, G7, H7,
    A8, B8, C8, D8, E8, F8, G8, H8 = *(0..64)

    SQUARES = [
      A1, B1, C1, D1, E1, F1, G1, H1,
      A2, B2, C2, D2, E2, F2, G2, H2,
      A3, B3, C3, D3, E3, F3, G3, H3,
      A4, B4, C4, D4, E4, F4, G4, H4,
      A5, B5, C5, D5, E5, F5, G5, H5,
      A6, B6, C6, D6, E6, F6, G6, H6,
      A7, B7, C7, D7, E7, F7, G7, H7,
      A8, B8, C8, D8, E8, F8, G8, H8
    ]

    SQUARES_180 = [
      A8, B8, C8, D8, E8, F8, G8, H8,
      A7, B7, C7, D7, E7, F7, G7, H7,
      A6, B6, C6, D6, E6, F6, G6, H6,
      A5, B5, C5, D5, E5, F5, G5, H5,
      A4, B4, C4, D4, E4, F4, G4, H4,
      A3, B3, C3, D3, E3, F3, G3, H3,
      A2, B2, C2, D2, E2, F2, G2, H2,
      A1, B1, C1, D1, E1, F1, G1, H1]

    SQUARES_L90 = [
      H1, H2, H3, H4, H5, H6, H7, H8,
      G1, G2, G3, G4, G5, G6, G7, G8,
      F1, F2, F3, F4, F5, F6, F7, F8,
      E1, E2, E3, E4, E5, E6, E7, E8,
      D1, D2, D3, D4, D5, D6, D7, D8,
      C1, C2, C3, C4, C5, C6, C7, C8,
      B1, B2, B3, B4, B5, B6, B7, B8,
      A1, A2, A3, A4, A5, A6, A7, A8]

    SQUARES_R45 = [
      A1, B8, C7, D6, E5, F4, G3, H2,
      A2, B1, C8, D7, E6, F5, G4, H3,
      A3, B2, C1, D8, E7, F6, G5, H4,
      A4, B3, C2, D1, E8, F7, G6, H5,
      A5, B4, C3, D2, E1, F8, G7, H6,
      A6, B5, C4, D3, E2, F1, G8, H7,
      A7, B6, C5, D4, E3, F2, G1, H8,
      A8, B7, C6, D5, E4, F3, G2, H1]

    SQUARES_L45 = [
      A2, B3, C4, D5, E6, F7, G8, H1,
      A3, B4, C5, D6, E7, F8, G1, H2,
      A4, B5, C6, D7, E8, F1, G2, H3,
      A5, B6, C7, D8, E1, F2, G3, H4,
      A6, B7, C8, D1, E2, F3, G4, H5,
      A7, B8, C1, D2, E3, F4, G5, H6,
      A8, B1, C2, D3, E4, F5, G6, H7,
      A1, B2, C3, D4, E5, F6, G7, H8]

    SQUARE_NAMES = [
      :a1, :b1, :c1, :d1, :e1, :f1, :g1, :h1,
      :a2, :b2, :c2, :d2, :e2, :f2, :g2, :h2,
      :a3, :b3, :c3, :d3, :e3, :f3, :g3, :h3,
      :a4, :b4, :c4, :d4, :e4, :f4, :g4, :h4,
      :a5, :b5, :c5, :d5, :e5, :f5, :g5, :h5,
      :a6, :b6, :c6, :d6, :e6, :f6, :g6, :h6,
      :a7, :b7, :c7, :d7, :e7, :f7, :g7, :h7,
      :a8, :b8, :c8, :d8, :e8, :f8, :g8, :h8]

    CASTLING_NONE            = 0
    CASTLING_WHITE_KINGSIDE  = 1
    CASTLING_BLACK_KINGSIDE  = 2
    CASTLING_WHITE_QUEENSIDE = 4
    CASTLING_BLACK_QUEENSIDE = 8
    CASTLING_WHITE           = CASTLING_WHITE_KINGSIDE | CASTLING_WHITE_QUEENSIDE
    CASTLING_BLACK           = CASTLING_BLACK_KINGSIDE | CASTLING_BLACK_QUEENSIDE
    CASTLING                 = CASTLING_WHITE | CASTLING_BLACK

    BB_VOID = 0b0000000000000000000000000000000000000000000000000000000000000000
    BB_ALL  = 0b1111111111111111111111111111111111111111111111111111111111111111

    BB_SQUARES = []
    SQUARES.each { |i| BB_SQUARES << (1 << i) }

    BB_A1, BB_B1, BB_C1, BB_D1, BB_E1, BB_F1, BB_G1, BB_H1,
    BB_A2, BB_B2, BB_C2, BB_D2, BB_E2, BB_F2, BB_G2, BB_H2,
    BB_A3, BB_B3, BB_C3, BB_D3, BB_E3, BB_F3, BB_G3, BB_H3,
    BB_A4, BB_B4, BB_C4, BB_D4, BB_E4, BB_F4, BB_G4, BB_H4,
    BB_A5, BB_B5, BB_C5, BB_D5, BB_E5, BB_F5, BB_G5, BB_H5,
    BB_A6, BB_B6, BB_C6, BB_D6, BB_E6, BB_F6, BB_G6, BB_H6,
    BB_A7, BB_B7, BB_C7, BB_D7, BB_E7, BB_F7, BB_G7, BB_H7,
    BB_A8, BB_B8, BB_C8, BB_D8, BB_E8, BB_F8, BB_G8, BB_H8 = *(BB_SQUARES)

    def self.pop_count(b)
      return b.to_s.count("1")
    end

    def self.bit_scan(b, n=0)
      string = b.to_s
      l = string.length
      r = string.slice(0, l - n).index("1")
      if r == -1
        return -1
      else
        return l - r - 1
      end
    end

    def self.shift_down(b)
      b >> 8
    end

    def self.shift_2_down(b)
      b >> 16
    end

    def self.shift_up(b)
      (b << 8) & BB_ALL
    end

    def self.shift_2_up(b)
      (b << 16) & BB_ALL
    end

    def self.shift_right(b)
      (b << 1) & ~BB_FILE_A
    end

    def self.shift_2_right(b)
      (b << 2) & ~BB_FILE_A & ~BB_FILE_B
    end

    def self.shift_left(b)
      (b >> 1) & ~BB_FILE_H
    end

    def self.shift_2_left(b)
      (b >> 2) & ~BB_FILE_G & ~BB_FILE_H
    end

    def self.shift_up_left(b)
      (b << 7) & ~BB_FILE_H
    end

    def self.shift_up_right(b)
      (b << 9) & ~BB_FILE_A
    end

    def self.shift_down_left(b)
      (b >> 9) & ~BB_FILE_H
    end

    def self.shift_down_right(b)
      (b >> 7) & ~BB_FILE_A
    end

    def self.l90(b)
      mask = Board::BB_VOID

      square = bit_scan(b)
      while square != - 1 and square do
        mask |= Board::BB_SQUARES_L90[square]
        square = bit_scan(b, square + 1)
      end

      return mask
    end

    def self.r45(b)
      mask = BB_VOID

      square = bit_scan(b)
      while square != - 1 and square do
        mask |= BB_SQUARES_R45[square]
        square = bit_scan(b, square + 1)
      end

      return mask
    end

    def self.l45(b)
      mask = Board::BB_VOID

      square = bit_scan(b)
      while square != - 1 and square do
        mask |= BB_SQUARES_L45[square]
        square = bit_scan(b, square + 1)
      end

      return mask
    end

    bb_light_squares = bb_dark_squares = BB_VOID

    BB_SQUARES.each_with_index do |mask, square|
      if (file_index(square) + rank_index(square)) % 2
        bb_light_squares |= mask
      else
        bb_dark_squares |= mask
      end
    end

    BB_SQUARES_L90 = [ ]
    SQUARES.each { |square| BB_SQUARES_L90 << BB_SQUARES[SQUARES_L90[square]] }

    BB_SQUARES_L45 = [ ]
    SQUARES.each { |square| BB_SQUARES_L45 << BB_SQUARES[SQUARES_L45[square]] }

    BB_SQUARES_R45 = [ ]
    SQUARES.each { |square| BB_SQUARES_R45 << BB_SQUARES[SQUARES_R45[square]] }

    BB_FILE_A = BB_A1 | BB_A2 | BB_A3 | BB_A4 | BB_A5 | BB_A6 | BB_A7 | BB_A8
    BB_FILE_B = BB_B1 | BB_B2 | BB_B3 | BB_B4 | BB_B5 | BB_B6 | BB_B7 | BB_B8
    BB_FILE_C = BB_C1 | BB_C2 | BB_C3 | BB_C4 | BB_C5 | BB_C6 | BB_C7 | BB_C8
    BB_FILE_D = BB_D1 | BB_D2 | BB_D3 | BB_D4 | BB_D5 | BB_D6 | BB_D7 | BB_D8
    BB_FILE_E = BB_E1 | BB_E2 | BB_E3 | BB_E4 | BB_E5 | BB_E6 | BB_E7 | BB_E8
    BB_FILE_F = BB_F1 | BB_F2 | BB_F3 | BB_F4 | BB_F5 | BB_F6 | BB_F7 | BB_F8
    BB_FILE_G = BB_G1 | BB_G2 | BB_G3 | BB_G4 | BB_G5 | BB_G6 | BB_G7 | BB_G8
    BB_FILE_H = BB_H1 | BB_H2 | BB_H3 | BB_H4 | BB_H5 | BB_H6 | BB_H7 | BB_H8

    BB_FILES = [
      BB_FILE_A,
      BB_FILE_B,
      BB_FILE_C,
      BB_FILE_D,
      BB_FILE_E,
      BB_FILE_F,
      BB_FILE_G,
      BB_FILE_H
    ]

    BB_RANK_1 = BB_A1 | BB_B1 | BB_C1 | BB_D1 | BB_E1 | BB_F1 | BB_G1 | BB_H1
    BB_RANK_2 = BB_A2 | BB_B2 | BB_C2 | BB_D2 | BB_E2 | BB_F2 | BB_G2 | BB_H2
    BB_RANK_3 = BB_A3 | BB_B3 | BB_C3 | BB_D3 | BB_E3 | BB_F3 | BB_G3 | BB_H3
    BB_RANK_4 = BB_A4 | BB_B4 | BB_C4 | BB_D4 | BB_E4 | BB_F4 | BB_G4 | BB_H4
    BB_RANK_5 = BB_A5 | BB_B5 | BB_C5 | BB_D5 | BB_E5 | BB_F5 | BB_G5 | BB_H5
    BB_RANK_6 = BB_A6 | BB_B6 | BB_C6 | BB_D6 | BB_E6 | BB_F6 | BB_G6 | BB_H6
    BB_RANK_7 = BB_A7 | BB_B7 | BB_C7 | BB_D7 | BB_E7 | BB_F7 | BB_G7 | BB_H7
    BB_RANK_8 = BB_A8 | BB_B8 | BB_C8 | BB_D8 | BB_E8 | BB_F8 | BB_G8 | BB_H8

    BB_RANKS = [
      BB_RANK_1,
      BB_RANK_2,
      BB_RANK_3,
      BB_RANK_4,
      BB_RANK_5,
      BB_RANK_6,
      BB_RANK_7,
      BB_RANK_8
    ]

    BB_KNIGHT_ATTACKS = []
    BB_SQUARES.each do |bb_square|
      mask = BB_VOID
      mask |= shift_left(shift_2_up(bb_square))
      mask |= shift_right(shift_2_up(bb_square))
      mask |= shift_left(shift_2_down(bb_square))
      mask |= shift_right(shift_2_down(bb_square))
      mask |= shift_2_left(shift_up(bb_square))
      mask |= shift_2_right(shift_up(bb_square))
      mask |= shift_2_left(shift_down(bb_square))
      mask |= shift_2_right(shift_down(bb_square))
      BB_KNIGHT_ATTACKS << (mask & BB_ALL)
    end

    BB_KING_ATTACKS = []
    BB_SQUARES.each do |bb_square|
      mask = BB_VOID
      mask |= shift_left(bb_square)
      mask |= shift_right(bb_square)
      mask |= shift_up(bb_square)
      mask |= shift_down(bb_square)
      mask |= shift_up_left(bb_square)
      mask |= shift_up_right(bb_square)
      mask |= shift_down_left(bb_square)
      mask |= shift_down_right(bb_square)
      BB_KING_ATTACKS << (mask & BB_ALL)
    end

    BB_RANK_ATTACKS = []
    BB_FILE_ATTACKS = []

    64.times do
      a = []
      64.times { a << BB_VOID }
      BB_RANK_ATTACKS << a
      BB_FILE_ATTACKS << a
    end

    SQUARES.each do |square|
      64.times do |bitrow|
        f = file_index(square) + 1
        q = square + 1
        while f < 8 do
          BB_RANK_ATTACKS[square][bitrow] |= BB_SQUARES[q]
          if (1 << f) & (bitrow << 1)
            break
          end
          q += 1
          f += 1
        end

        f = file_index(square) - 1
        q = square - 1
        while f >= 0 do
          BB_RANK_ATTACKS[square][bitrow] |= BB_SQUARES[q]
          if (1 << f) & (bitrow << 1)
            break
          end
          q -= 1
          f -= 1
        end

        r = rank_index(square) + 1
        q = square + 8
        while r < 8 do
          BB_FILE_ATTACKS[square][bitrow] |= BB_SQUARES[q]
          if (1 << (7 - r)) & (bitrow << 1)
            break
          end
          q += 8
          r += 1
        end

        r = rank_index(square) - 1
        q = square - 8
        while r >= 0 do
          BB_FILE_ATTACKS[square][bitrow] |= BB_SQUARES[q]
          if (1 << (7 - r)) & (bitrow << 1)
            break
          end
          q -= 8
          r -= 1
        end
      end
    end

    BB_SHIFT_R45 = [
      1, 58, 51, 44, 37, 30, 23, 16,
      9, 1, 58, 51, 44, 37, 30, 23,
      17, 9, 1, 58, 51, 44, 37, 30,
      25, 17, 9, 1, 58, 51, 44, 37,
      33, 25, 17, 9, 1, 58, 51, 44,
      41, 33, 25, 17, 9, 1, 58, 51,
      49, 41, 33, 25, 17, 9, 1, 58,
      57, 49, 41, 33, 25, 17, 9, 1]

    BB_SHIFT_L45 = [
      9, 17, 25, 33, 41, 49, 57, 1,
      17, 25, 33, 41, 49, 57, 1, 10,
      25, 33, 41, 49, 57, 1, 10, 19,
      33, 41, 49, 57, 1, 10, 19, 28,
      41, 49, 57, 1, 10, 19, 28, 37,
      49, 57, 1, 10, 19, 28, 37, 46,
      57, 1, 10, 19, 28, 37, 46, 55,
      1, 10, 19, 28, 37, 46, 55, 64]

    BB_L45_ATTACKS = []
    BB_R45_ATTACKS = []
    64.times do
      a = []
      64.times { a << BB_VOID }
      BB_L45_ATTACKS << a
      BB_R45_ATTACKS << a
    end

    SQUARES.each do |s|
      64.times do |b|
        mask = BB_VOID

        q = s
        while file_index(q) > 0 and rank_index(q) < 7 do
          q += 7
          mask |= BB_SQUARES[q]
          if b & (BB_SQUARES_L45[q] >> BB_SHIFT_L45[s])
            break
          end
        end

        q = s
        while file_index(q) < 7 and rank_index(q) > 0 do
          q -= 7
          mask |= BB_SQUARES[q]
          if b & (BB_SQUARES_L45[q] >> BB_SHIFT_L45[s])
            break
          end
        end

        BB_L45_ATTACKS[s][b] = mask

        mask = BB_VOID

        q = s
        while file_index(q) < 7 and rank_index(q) < 7 do
          q += 9
          mask |= BB_SQUARES[q]
          if b & (BB_SQUARES_R45[q] >> BB_SHIFT_R45[s])
            break
          end
        end

        q = s
        while file_index(q) > 0 and rank_index(q) > 0 do
          q -= 9
          mask |= BB_SQUARES[q]
          if b & (BB_SQUARES_R45[q] >> BB_SHIFT_R45[s])
            break
          end
        end

        BB_R45_ATTACKS[s][b] = mask
      end
    end

    BB_PAWN_ATTACKS = [[], []]
    BB_SQUARES.each do |s|
      BB_PAWN_ATTACKS[0].push(*[shift_up_left(s) | shift_up_right(s)])
      BB_PAWN_ATTACKS[1].push(*[shift_down_left(s) | shift_down_right(s)])
    end

    BB_PAWN_F1 = [[], []]
    BB_SQUARES.each do |s|
      BB_PAWN_F1[0].push(*[shift_up(s)])
      BB_PAWN_F1[1].push(*[shift_down(s)])
    end

    BB_PAWN_F2 = [[], []]
    BB_SQUARES.each do |s|
      BB_PAWN_F2[0].push(*[shift_2_up(s)])
      BB_PAWN_F2[1].push(*[shift_2_down(s)])
    end

    BB_PAWN_ALL = [[], []]
    SQUARES.each do |i|
      BB_PAWN_ALL[0].push(*[BB_PAWN_ATTACKS[0][i] | BB_PAWN_F1[0][i] | BB_PAWN_F2[0][i]])
      BB_PAWN_ALL[1].push(*[BB_PAWN_ATTACKS[1][i] | BB_PAWN_F1[1][i] | BB_PAWN_F2[1][i]])
    end

    ###
    # A bitboard and additional information representing a position.
    #
    # Provides move generation, validation, parsing, attack generation,
    # game end detection, move counters and the capability to make and unmake
    # moves.
    #
    # The bitboard is initialized to the starting position, unless otherwise
    # specified in the optional `fen` argument.
    ###
    def initialize(fen = nil)
      if fen == nil
        reset
      else
        set_fen(fen)
      end
    end

    def reset
      ## Restores the starting position
      pawns   = BB_RANK_2 | BB_RANK_7
      knights = BB_B1 | BB_G1 | BB_B8 | BB_G8
      bishops = BB_C1 | BB_F1 | BB_C8 | BB_F8
      rooks   = BB_A1 | BB_H1 | BB_A8 | BB_H8
      queens  = BB_D1 | BB_D8
      kings   = BB_E1 | BB_E8

      occupied_co = [BB_RANK_1 | BB_RANK_2,  BB_RANK_7 | BB_RANK_8]
      occupied    =  BB_RANK_1 | BB_RANK_2 | BB_RANK_7 | BB_RANK_8

      occupied_l90 = BB_VOID
      occupied_l45 = BB_VOID
      occupied_r45 = BB_VOID

      king_squares = [E1, E8]
      pieces = Array.new(64)

      64.times do |i|
        mask = BB_SQUARES[i]
        if mask & pawns
          pieces[i] = PAWN
        elsif mask & knights
          pieces[i] = KNIGHT
        elsif mask & bishops
          pieces[i] = BISHOP
        elsif mask & rooks
          pieces[i] = ROOK
        elsif mask & queens
          pieces[i] = QUEEN
        elsif mask & kings
          pieces[i] = KING
        end
      end

      ep_square       = 0
      castling_rights = CASTLING
      turn            = WHITE
      fullmove_number = 1
      halfmove_clock  = 0

      64.times do |i|
        if BB_SQUARES[i] & occupied
          occupied_l90 |= BB_SQUARES_L90[i]
          occupied_r45 |= BB_SQUARES_R45[i]
          occupied_l45 |= BB_SQUARES_L45[i]
        end
      end

      halfmove_clock_stack = Hamster.deque
      captured_piece_stack = Hamster.deque
      castling_right_stack = Hamster.deque
      ep_square_stack      = Hamster.deque
      move_stack           = Hamster.deque

      incremental_zobrist_hash = board_zobrist_hash(POLYGLOT_RANDOM_ARRAY)
      transpositions           = {}
    end

    def clear
      ###
      # Clears the board.
      #
      # Resets move stacks and move counters. The side to move is white. There
      # are no rooks or kings, so castling is not allowed.
      #
      # In order to be in a valid `status()` at least kings need to be put on
      # the board. This is required for move generation and validation to work
      # properly.
      ###

      pawns   = BB_VOID
      knights = BB_VOID
      bishops = BB_VOID
      rooks   = BB_VOID
      queens  = BB_VOID
      kings   = BB_VOID

      occupied_co = [BB_VOID, BB_VOID]
      occupied    = BB_VOID

      occupied_l90 = BB_VOID
      occupied_r45 = BB_VOID
      occupied_l45 = BB_VOID

      king_squares = [E1, E8]
      pieces       = Array.new(64)

      halfmove_clock_stack = Hamster.deque
      captured_piece_stack = Hamster.deque
      castling_right_stack = Hamster.deque
      ep_square_stack      = Hamster.deque
      move_stack           = Hamster.deque

      ep_square       = 0
      castling_rights = CASTLING_nil
      turn            = WHITE
      fullmove_number = 1
      halfmove_clock  = 0

      incremental_zobrist_hash = board_zobrist_hash(POLYGLOT_RANDOM_ARRAY)
      transpositions           = {zobrist_hash => '0'}
    end

    def file_index(square)
      # Gets the file index of square where `0` is the a file
      return square & 7
    end

    def rank_index(square)
      # Gets the rank index of the square where `0` is the first rank
      return square >> 3
    end

    def piece_at(square)
      # Gets the piece at the given square
      mask  = BB_SQUARES[square]
      color = (occupied_co[BLACK] & mask).to_i

      piece_type = piece_type_at(square)
      if piece_type
        return Piece.new(piece_type, color)
      end
    end

    def piece_type_at(square)
      # Gets the piece type at the given square
      pieces[square]
    end

    def remove_piece_at(square)
      # Removes a piece from the given square if present
      piece_type = pieces[square]

      return nil unless piece_type

      mask = BB_SQUARES[square]

      if piece_type == PAWN
        pawns ^= mask
      elsif piece_type == KNIGHT
        knights ^= mask
      elsif piece_type == BISHOP
        bishops ^= mask
      elsif piece_type == ROOK
        rooks ^= mask
      elsif piece_type == QUEEN
        queens ^= mask
      else
        kings ^= mask
      end

      color = (occupied_co[BLACK] & mask).to_i

      pieces[square]      = nil
      occupied           ^= mask
      occupied_co[color] ^= mask
      occupied_l90       ^= BB_SQUARES[SQUARES_L90[square]]
      occupied_r45       ^= BB_SQUARES[SQUARES_R45[square]]
      occupied_l45       ^= BB_SQUARES[SQUARES_L45[square]]

      # Update incremental zobrist hash.
      if color == BLACK
        piece_index = (piece_type - 1) * 2
      else
        piece_index = (piece_type - 1) * 2 + 1
      end

      incremental_zobrist_hash ^= POLYGLOT_RANDOM_ARRAY[64 * piece_index + 8 * rank_index(square) + file_index(square)]
    end

    # Sets a piece at the given square. An existing piece is replaced
    def set_piece_at(square, piece)
      remove_piece_at(square)

      pieces[square] = piece.piece_type

      mask = BB_SQUARES[square]

      if piece.piece_type == PAWN
        pawns |= mask
      elsif piece.piece_type == KNIGHT
        knights |= mask
      elsif piece.piece_type == BISHOP
        bishops |= mask
      elsif piece.piece_type == ROOK
        rooks |= mask
      elsif piece.piece_type == QUEEN
        queens |= mask
      elsif piece.piece_type == KING
        kings |= mask
        king_squares[piece.color] = square
      end

      occupied                 ^= mask
      occupied_co[piece.color] ^= mask
      occupied_l90             ^= BB_SQUARES[SQUARES_L90[square]]
      occupied_r45             ^= BB_SQUARES[SQUARES_R45[square]]
      occupied_l45             ^= BB_SQUARES[SQUARES_L45[square]]

      # Update incremental zorbist hash.
      if piece.color == BLACK
        piece_index = (piece.piece_type - 1) * 2
      else
        piece_index = (piece.piece_type - 1) * 2 + 1
      end

      incremental_zobrist_hash ^= POLYGLOT_RANDOM_ARRAY[64 * piece_index + 8 * rank_index(square) + file_index(square)]
    end

    def is_legal(move)
      return is_pseudo_legal(move) && !is_into_check(move)
    end

    def push(move)
      ###
      # Updates the position with the given move and puts it onto a stack.
      #
      # Null moves just increment the move counters, switch turns and forfeit
      # en passant capturing.
      #
      # No validation is performed. For performance moves are assumed to be at
      # least pseudo legal. Otherwise there is no guarantee that the previous
      # board state can be restored. To check it yourself you can use:
      #
      # >>> move in board.pseudo_legal_moves true

      # Increment fullmove number.
      if turn == BLACK
        fullmove_number += 1
      end

      # Remember game state.
      captured_piece = nil
      captured_piece = piece_type_at(move.to_square) if move
      halfmove_clock_stack.append(halfmove_clock)
      castling_right_stack.append(castling_rights)
      captured_piece_stack.append(captured_piece)
      ep_square_stack.append(ep_square)
      move_stack.append(move)

      # On a null move simply swap turns.
      unless move
        turn           ^= 1
        ep_square       = 0
        halfmove_clock += 1
        return
      end

      # Update half move counter.
      piece_type = piece_type_at(move.from_square)
      if piece_type == PAWN or captured_piece
        halfmove_clock = 0
      else
        halfmove_clock += 1
      end

      # Promotion.
      if move.promotion
        piece_type = move.promotion
      end

      # Remove piece from target square.
      remove_piece_at(move.from_square)

      # Handle special pawn moves.
      ep_square = 0
      if piece_type == PAWN
        diff = (move.to_square - move.from_square).abs

        # Remove pawns captured en-passant.
        if (diff == 7 or diff == 9) && !occupied & BB_SQUARES[move.to_square]
          if turn == WHITE
            remove_piece_at(move.to_square - 8)
          else
            remove_piece_at(move.to_square + 8)
          end
        end

        # Set en-passant square.
        if diff == 16
          if turn == WHITE
            ep_square = move.to_square - 8
          else
            ep_square = move.to_square + 8
          end
        end
      end

      # Castling rights.
      if move.from_square == E1
        castling_rights &= ~CASTLING_WHITE
      elsif move.from_square == E8
        castling_rights &= ~CASTLING_BLACK
      elsif move.from_square == A1 or move.to_square == A1
        castling_rights &= ~CASTLING_WHITE_QUEENSIDE
      elsif move.from_square == A8 or move.to_square == A8
        castling_rights &= ~CASTLING_BLACK_QUEENSIDE
      elsif move.from_square == H1 or move.to_square == H1
        castling_rights &= ~CASTLING_WHITE_KINGSIDE
      elsif move.from_square == H8 or move.to_square == H8
        castling_rights &= ~CASTLING_BLACK_KINGSIDE
      end

      # Castling.
      if piece_type == KING
        if move.from_square == E1 and move.to_square == G1
          set_piece_at(F1, Piece.new(ROOK, WHITE))
          remove_piece_at(H1)
        elsif move.from_square == E1 and move.to_square == C1
          set_piece_at(D1, Piece.new(ROOK, WHITE))
          remove_piece_at(A1)
        elsif move.from_square == E8 and move.to_square == G8
          set_piece_at(F8, Piece.new(ROOK, BLACK))
          remove_piece_at(H8)
        elsif move.from_square == E8 and move.to_square == C8
          set_piece_at(D8, Piece.new(ROOK, BLACK))
          remove_piece_at(A8)
        end
      end

      # Put piece on target square.
      set_piece_at(move.to_square, Piece.new(piece_type, turn))

      # Swap turn.
      turn ^= 1

      # Update transposition table.
      transpositions[zobrist_hash] += 1
    end

    def pop
      ###
      # Restores the previous position and returns the last move from the stack.
      ###
      move = move_stack.pop()

      # Update transposition table.
      transpositions[zobrist_hash] -= 1

      # Decrement fullmove number.
      if turn == WHITE
        fullmove_number -= 1
      end

      # Restore state.
      halfmove_clock       = halfmove_clock_stack.pop()
      castling_rights      = castling_right_stack.pop()
      ep_square            = ep_square_stack.pop()
      captured_piece       = captured_piece_stack.pop()
      captured_piece_color = turn

      # On a null move simply swap the turn.
      unless move
        turn ^= 1
        return move
      end

      # Restore the source square.
      piece = nil
      if move.promotion
        piece = PAWN
      else
        piece_type_at(move.to_square)
      end
      set_piece_at(move.from_square, Piece.new(piece, turn ^ 1))

      # Restore target square.
      if captured_piece
        set_piece_at(move.to_square, Piece.new(captured_piece, captured_piece_color))
      else
        remove_piece_at(move.to_square)

        # Restore captured pawn after en-passant.
         num = move.from_square - move.to_square
        if piece == PAWN && ([7, 9].include?(num.abs))
          if turn == WHITE
            set_piece_at(move.to_square + 8, Piece.new(PAWN, WHITE))
          else
            set_piece_at(move.to_square - 8, Piece.new(PAWN, BLACK))
          end
        end
      end

      # Restore rook position after castling.
      if piece == KING
        if move.from_square == E1 and move.to_square == G1
          remove_piece_at(F1)
          set_piece_at(H1, Piece.new(ROOK, WHITE))
        elsif move.from_square == E1 and move.to_square == C1
          remove_piece_at(D1)
          set_piece_at(A1, Piece.new(ROOK, WHITE))
        elsif move.from_square == E8 and move.to_square == G8
          remove_piece_at(F8)
          set_piece_at(H8, Piece.new(ROOK, BLACK))
        elsif move.from_square == E8 and move.to_square == C8
          remove_piece_at(D8)
          set_piece_at(A8, Piece.new(ROOK, BLACK))
        end
      end

      # Swap turn.
      turn ^= 1

      return move
    end

    def peek
      # Gets the last move from the move stack
      return move_stack.last
    end

    def to_s
      builder = []
      SQUARES_180.each do |square|
        piece = piece_at(square)

        if piece
          builder.push(piece.symbol())
        else
          builder.push(".")
        end

        if BB_SQUARES[square] & BB_FILE_H
          if square != H1
            builder.push("\n")
          end
        else
          builder.push(" ")
        end
      end

      return builder.join('')
    end

    def ==(bitboard)
      return !not_equal?(bitboard)
    end

    def not_equal?(bitboard)
      if occupied != bitboard.occupied
        return true
      end

      if occupied_co[WHITE] != bitboard.occupied_co[WHITE]
        return true
      end

      if pawns != bitboard.pawns
        return true
      end

      if knights != bitboard.knights
        return true
      end

      if bishops != bitboard.bishops
        return true
      end

      if rooks != bitboard.rooks
        return true
      end

      if queens != bitboard.queens
        return true
      end

      if kings != bitboard.kings
        return true
      end

      if ep_square != bitboard.ep_square
        return true
      end

      if castling_rights != bitboard.castling_rights
        return true
      end

      if turn != bitboard.turn
        return true
      end

      if fullmove_number != bitboard.fullmove_number
        return true
      end

      if halfmove_clock != bitboard.halfmove_clock
        return true
      end

      return false
    end
  end
end
