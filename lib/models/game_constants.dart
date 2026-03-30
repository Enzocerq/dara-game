const int kRows = 5;
const int kCols = 6;
const int kPiecesPerPlayer = 12;

enum GamePhase {
  placement,
  movement,
  capture,
  gameOver,
}
