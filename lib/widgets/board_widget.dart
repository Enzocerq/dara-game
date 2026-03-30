import 'package:flutter/material.dart';
import '../models/game_constants.dart';

class BoardWidget extends StatelessWidget {
  final List<List<int>> board;
  final int myPlayer;
  final GamePhase phase;
  final int? selectedRow;
  final int? selectedCol;
  final void Function(int row, int col) onCellTap;

  const BoardWidget({
    super.key,
    required this.board,
    required this.myPlayer,
    required this.phase,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellTap,
  });

  bool _isAdjacent(int fromRow, int fromCol, int toRow, int toCol) {
    int dr = (fromRow - toRow).abs();
    int dc = (fromCol - toCol).abs();
    return (dr + dc) == 1;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: kCols / kRows,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.brown.shade700,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade400, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: kCols,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemCount: kRows * kCols,
          itemBuilder: (context, index) {
            int row = index ~/ kCols;
            int col = index % kCols;
            return _buildCell(row, col);
          },
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    int cellValue = board[row][col];
    bool isSelected = (row == selectedRow && col == selectedCol);

    bool isValidTarget = false;
    if (phase == GamePhase.movement &&
        selectedRow != null &&
        cellValue == 0 &&
        _isAdjacent(selectedRow!, selectedCol!, row, col)) {
      isValidTarget = true;
    }

    bool isCapturable = false;
    if (phase == GamePhase.capture) {
      int opponent = myPlayer == 1 ? 2 : 1;
      isCapturable = (cellValue == opponent);
    }

    Color bgColor;
    Color borderColor;
    double borderWidth;

    if (isSelected) {
      bgColor = Colors.yellow.withOpacity(0.3);
      borderColor = Colors.yellow;
      borderWidth = 2.5;
    } else if (isValidTarget) {
      bgColor = Colors.green.withOpacity(0.25);
      borderColor = Colors.greenAccent;
      borderWidth = 2;
    } else if (isCapturable) {
      bgColor = Colors.red.withOpacity(0.25);
      borderColor = Colors.redAccent;
      borderWidth = 2;
    } else {
      bgColor = Colors.brown.shade600;
      borderColor = Colors.brown.shade500;
      borderWidth = 1;
    }

    return GestureDetector(
      onTap: () => onCellTap(row, col),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Center(
          child: cellValue != 0
              ? FractionallySizedBox(
                  widthFactor: 0.65,
                  heightFactor: 0.65,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cellValue == 1
                          ? Colors.blue.shade400
                          : Colors.red.shade400,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 3,
                          offset: const Offset(1, 2),
                        ),
                      ],
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.3),
                        colors: cellValue == 1
                            ? [Colors.blue.shade200, Colors.blue.shade600]
                            : [Colors.red.shade200, Colors.red.shade600],
                      ),
                    ),
                  ),
                )
              : Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.brown.shade400.withOpacity(0.5),
                  ),
                ),
        ),
      ),
    );
  }
}
