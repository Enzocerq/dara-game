import 'package:flutter/material.dart';
import '../models/game_constants.dart';

class InfoBar extends StatelessWidget {
  final GamePhase phase;
  final int myPlayer;
  final int currentTurn;
  final int myPieces;
  final int opPieces;
  final int placedPlayer1;
  final int placedPlayer2;
  final String statusMessage;
  final bool isError;

  const InfoBar({
    super.key,
    required this.phase,
    required this.myPlayer,
    required this.currentTurn,
    required this.myPieces,
    required this.opPieces,
    required this.placedPlayer1,
    required this.placedPlayer2,
    required this.statusMessage,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    String phaseLabel = switch (phase) {
      GamePhase.placement =>
        'COLOCAÇÃO  (${placedPlayer1 + placedPlayer2} / ${kPiecesPerPlayer * 2})',
      GamePhase.movement => 'MOVIMENTAÇÃO',
      GamePhase.capture => '⚡ CAPTURA',
      GamePhase.gameOver => 'FIM DE JOGO',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.brown.shade900,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(phaseLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              Row(
                children: [
                  _pieceCounter(myPlayer, myPieces, 'Você'),
                  const SizedBox(width: 16),
                  _pieceCounter(myPlayer == 1 ? 2 : 1, opPieces, 'Oponente'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            statusMessage,
            style: TextStyle(
              color: isError
                  ? Colors.redAccent
                  : phase == GamePhase.gameOver
                      ? Colors.grey.shade400
                      : phase == GamePhase.capture
                          ? Colors.orangeAccent
                          : currentTurn == myPlayer
                              ? Colors.greenAccent
                              : Colors.grey.shade400,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _pieceCounter(int player, int count, String label) {
    Color color = player == 1 ? Colors.blue.shade400 : Colors.red.shade400;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text('$label: $count', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
