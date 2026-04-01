import 'dart:io';
import 'package:flutter/material.dart';
import '../models/game_constants.dart';
import '../services/socket_service.dart';
import '../widgets/board_widget.dart';
import '../widgets/chat_widget.dart';
import '../widgets/info_bar_widget.dart';
import 'connection_screen.dart';

class GameScreen extends StatefulWidget {
  final Socket socket;
  final bool isHost;
  final ServerSocket? serverSocket;

  const GameScreen({
    super.key,
    required this.socket,
    required this.isHost,
    this.serverSocket,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<int>> board;
  late SocketService _socketService;

  late int myPlayer;
  late int currentTurn;
  GamePhase phase = GamePhase.placement;

  int placedPlayer1 = 0;
  int placedPlayer2 = 0;

  int? selectedRow;
  int? selectedCol;

  final List<String> chatMessages = [];
  final _chatController = TextEditingController();
  final _chatScrollController = ScrollController();

  String statusMessage = '';
  bool statusIsError = false;

  // Controle de revanche
  bool _iWantRematch = false;
  bool _opponentWantsRematch = false;
  void Function(void Function())? _dialogSetState;

  /// Inicializa o estado do jogo ao entrar na tela.
  /// Define o tabuleiro vazio, identifica qual jogador é o local (host = 1,
  /// cliente = 2), configura os callbacks do socket e inicia a escuta.
  @override
  void initState() {
    super.initState();

    board = List.generate(kRows, (_) => List.filled(kCols, 0));

    myPlayer = widget.isHost ? 1 : 2;
    currentTurn = 1;

    statusMessage = widget.isHost
        ? 'Sua vez — toque em uma casa para colocar sua peça'
        : 'Aguardando o oponente jogar...';

    _socketService = SocketService(widget.socket);
    _socketService.onMessage = _handleIncomingMessage;
    _socketService.onError = (e) {
      setState(() => statusMessage = 'Erro na conexão: $e');
    };
    _socketService.onDone = () {
      setState(() {
        if (phase != GamePhase.gameOver) {
          statusMessage = 'Conexão perdida com o oponente!';
          phase = GamePhase.gameOver;
        }
      });
    };
    _socketService.startListening();
  }

  // ============================================================
  // PROCESSAMENTO DE MENSAGENS RECEBIDAS
  // ============================================================

  /// Processa cada mensagem JSON recebida pelo socket do oponente.
  /// Atualiza o estado local do tabuleiro e avança a fase do jogo conforme
  /// o tipo da mensagem recebida.
  void _handleIncomingMessage(Map<String, dynamic> msg) {
    setState(() {
      switch (msg['type']) {
        case 'place':
          int r = msg['row'];
          int c = msg['col'];
          int opponent = myPlayer == 1 ? 2 : 1;

          board[r][c] = opponent;

          if (opponent == 1) {
            placedPlayer1++;
          } else {
            placedPlayer2++;
          }

          _advanceTurn();
          break;

        case 'move':
          int fr = msg['fromRow'];
          int fc = msg['fromCol'];
          int tr = msg['toRow'];
          int tc = msg['toCol'];

          board[tr][tc] = board[fr][fc];
          board[fr][fc] = 0;

          if (msg['formedLine'] == true) {
            statusMessage =
                'Oponente formou 3 em linha! Aguardando captura...';
          } else {
            _advanceTurn();
          }
          break;

        case 'capture':
          int r = msg['row'];
          int c = msg['col'];

          board[r][c] = 0;

          _checkWinCondition();

          if (phase != GamePhase.gameOver) {
            _advanceTurn();
          }
          break;

        case 'chat':
          chatMessages.add('Oponente: ${msg['message']}');
          _scrollChatToBottom();
          break;

        case 'surrender':
          phase = GamePhase.gameOver;
          statusMessage = 'Fim de jogo';
          _showGameOverDialog(true, 'O oponente desistiu! Você venceu!');
          break;

        case 'rematch_request':
          _opponentWantsRematch = true;
          if (_iWantRematch) {
            _startRematch();
          } else {
            _dialogSetState?.call(() {});
          }
          break;

        case 'rematch_cancel':
          _opponentWantsRematch = false;
          _dialogSetState?.call(() {});
          break;
      }
    });
  }

  // ============================================================
  // LÓGICA DO JOGO
  // ============================================================

  /// Passa o turno para o outro jogador. Se ambos já colocaram todas as peças,
  /// avança da fase de colocação para a fase de movimento.
  void _advanceTurn() {
    currentTurn = currentTurn == 1 ? 2 : 1;

    if (phase == GamePhase.placement &&
        placedPlayer1 >= kPiecesPerPlayer &&
        placedPlayer2 >= kPiecesPerPlayer) {
      phase = GamePhase.movement;
    }

    _refreshStatusMessage();
  }

  /// Atualiza a mensagem de status exibida na InfoBar de acordo com a fase
  /// atual do jogo e de quem é o turno.
  void _refreshStatusMessage() {
    statusIsError = false;
    if (phase == GamePhase.gameOver) return;

    bool isMyTurn = currentTurn == myPlayer;

    switch (phase) {
      case GamePhase.placement:
        int remaining = myPlayer == 1
            ? kPiecesPerPlayer - placedPlayer1
            : kPiecesPerPlayer - placedPlayer2;
        statusMessage = isMyTurn
            ? 'Sua vez — coloque uma peça ($remaining restantes)'
            : 'Aguardando oponente colocar peça...';
        break;

      case GamePhase.capture:
        statusMessage = 'Toque em uma peça do oponente para capturá-la!';
        break;

      case GamePhase.movement:
        statusMessage = isMyTurn
            ? 'Sua vez — selecione uma peça e mova para casa adjacente'
            : 'Aguardando oponente mover...';
        break;

      default:
        break;
    }
  }

  /// Verifica, sem alterar o estado real, se colocar uma peça do [player]
  /// em (row, col) formaria um alinhamento de 3 ou mais.
  bool _wouldFormLine(int row, int col, int player) {
    board[row][col] = player;
    bool result = _isPartOfLine(row, col, player);
    board[row][col] = 0;
    return result;
  }

  /// Retorna o maior alinhamento (horizontal ou vertical) que a peça
  /// em (row, col) forma com peças do mesmo jogador.
  int _maxLineLength(int row, int col, int player) {
    int hCount = 1;
    for (int c = col - 1; c >= 0 && board[row][c] == player; c--) {
      hCount++;
    }
    for (int c = col + 1; c < kCols && board[row][c] == player; c++) {
      hCount++;
    }

    int vCount = 1;
    for (int r = row - 1; r >= 0 && board[r][col] == player; r--) {
      vCount++;
    }
    for (int r = row + 1; r < kRows && board[r][col] == player; r++) {
      vCount++;
    }

    return hCount > vCount ? hCount : vCount;
  }

  /// Retorna true se a peça em (row, col) faz parte de um alinhamento
  /// de 3 ou mais peças do [player] (horizontal ou vertical).
  bool _isPartOfLine(int row, int col, int player) {
    return _maxLineLength(row, col, player) >= 3;
  }

  /// Retorna true se as células (fromRow, fromCol) e (toRow, toCol) são
  /// adjacentes ortogonalmente (cima, baixo, esquerda, direita).
  bool _isAdjacent(int fromRow, int fromCol, int toRow, int toCol) {
    int dr = (fromRow - toRow).abs();
    int dc = (fromCol - toCol).abs();
    return (dr + dc) == 1;
  }

  /// Conta e retorna o total de peças do [player] presentes no tabuleiro.
  int _countPieces(int player) {
    int count = 0;
    for (var row in board) {
      for (var cell in row) {
        if (cell == player) count++;
      }
    }
    return count;
  }

  /// Verifica se algum jogador atingiu a condição de vitória (oponente com
  /// 2 ou menos peças) e exibe o diálogo de fim de jogo quando necessário.
  void _checkWinCondition() {
    if (phase != GamePhase.movement && phase != GamePhase.capture) return;

    int opponent = myPlayer == 1 ? 2 : 1;
    int myPieces = _countPieces(myPlayer);
    int opponentPieces = _countPieces(opponent);

    if (opponentPieces <= 2) {
      phase = GamePhase.gameOver;
      statusMessage = 'Fim de jogo';
      _showGameOverDialog(true, 'Você venceu! Oponente ficou com $opponentPieces peças.');
    } else if (myPieces <= 2) {
      phase = GamePhase.gameOver;
      statusMessage = 'Fim de jogo';
      _showGameOverDialog(false, 'Você perdeu! Restam apenas $myPieces peças.');
    }
  }

  // ============================================================
  // INTERAÇÕES DO JOGADOR
  // ============================================================

  /// Trata o toque do jogador em uma célula do tabuleiro.
  /// O comportamento varia conforme a fase atual: colocação, movimento ou
  /// captura. Valida a jogada, atualiza o estado local e envia a mensagem
  /// correspondente ao oponente via socket.
  void _onCellTap(int row, int col) {
    if (phase == GamePhase.gameOver) return;

    setState(() {
      if (phase == GamePhase.capture) {
        int opponent = myPlayer == 1 ? 2 : 1;

        if (board[row][col] == opponent) {
          board[row][col] = 0;

          _socketService.send({'type': 'capture', 'row': row, 'col': col});

          phase = GamePhase.movement;

          _checkWinCondition();

          if (phase != GamePhase.gameOver) {
            _advanceTurn();
          }
        } else {
          statusMessage = 'Toque em uma peça VERMELHA/AZUL do oponente!';
          statusIsError = true;
        }
        return;
      }

      if (currentTurn != myPlayer) return;

      if (phase == GamePhase.placement) {
        if (board[row][col] != 0) return;

        if (_wouldFormLine(row, col, myPlayer)) {
          statusMessage =
              '⚠ Proibido formar 3 em linha na fase de colocação!';
          statusIsError = true;
          return;
        }

        board[row][col] = myPlayer;

        if (myPlayer == 1) {
          placedPlayer1++;
        } else {
          placedPlayer2++;
        }

        _socketService.send({'type': 'place', 'row': row, 'col': col});

        _advanceTurn();
        return;
      }

      if (phase == GamePhase.movement) {
        if (selectedRow == null) {
          if (board[row][col] == myPlayer) {
            selectedRow = row;
            selectedCol = col;
            statusMessage = 'Peça selecionada! Toque em casa adjacente vazia.';
          }
          return;
        }

        if (row == selectedRow && col == selectedCol) {
          selectedRow = null;
          selectedCol = null;
          statusMessage = 'Seleção cancelada.';
          return;
        }

        if (board[row][col] == myPlayer) {
          selectedRow = row;
          selectedCol = col;
          statusMessage = 'Seleção alterada. Toque em casa adjacente vazia.';
          return;
        }

        if (board[row][col] == 0 &&
            _isAdjacent(selectedRow!, selectedCol!, row, col)) {
          // Simula o movimento para verificar alinhamento
          board[row][col] = myPlayer;
          board[selectedRow!][selectedCol!] = 0;

          int lineLen = _maxLineLength(row, col, myPlayer);

          // Mais de 3 em linha não é permitido — desfaz o movimento
          if (lineLen > 3) {
            board[selectedRow!][selectedCol!] = myPlayer;
            board[row][col] = 0;
            statusMessage =
                '⚠ Proibido formar mais de 3 em linha!';
            statusIsError = true;
            return;
          }

          int fromR = selectedRow!;
          int fromC = selectedCol!;

          selectedRow = null;
          selectedCol = null;

          bool formedLine = (lineLen == 3);

          _socketService.send({
            'type': 'move',
            'fromRow': fromR,
            'fromCol': fromC,
            'toRow': row,
            'toCol': col,
            'formedLine': formedLine,
          });

          if (formedLine) {
            phase = GamePhase.capture;
            statusMessage =
                '🎯 Você formou 3 em linha! Toque em uma peça do oponente.';
          } else {
            _advanceTurn();
          }
        } else if (board[row][col] != 0) {
          statusMessage = 'Casa ocupada! Escolha uma casa vazia adjacente.';
          statusIsError = true;
        } else {
          statusMessage = 'Muito longe! Mova apenas para casas adjacentes.';
          statusIsError = true;
        }
      }
    });
  }

  // ============================================================
  // CHAT E DESISTÊNCIA
  // ============================================================

  /// Envia a mensagem digitada no campo de chat ao oponente via socket
  /// e a adiciona à lista local de mensagens.
  void _sendChat() {
    String text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      chatMessages.add('Você: $text');
    });

    _socketService.send({'type': 'chat', 'message': text});

    _chatController.clear();
    _scrollChatToBottom();
  }

  /// Exibe um diálogo de confirmação de desistência. Se confirmado, envia
  /// a mensagem de rendição ao oponente e encerra a partida localmente.
  void _surrender() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desistir da partida?'),
        content: const Text(
          'Ao desistir, seu oponente será declarado vencedor. '
          'Tem certeza?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _socketService.send({'type': 'surrender'});
              setState(() {
                phase = GamePhase.gameOver;
                statusMessage = 'Fim de jogo';
              });
              _showGameOverDialog(false, 'Você desistiu. Oponente venceu!');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desistir'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIÁLOGO DE FIM DE JOGO E REVANCHE
  // ============================================================

  /// Exibe o diálogo de fim de jogo com o resultado da partida.
  /// Gerencia o fluxo de revanche: ambos os jogadores precisam confirmar
  /// para que uma nova partida seja iniciada.
  void _showGameOverDialog(bool isWinner, String message) {
    _iWantRematch = false;
    _opponentWantsRematch = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            _dialogSetState = setDialogState;
            return AlertDialog(
              icon: Icon(
                isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 48,
                color: isWinner ? Colors.amber : Colors.red.shade300,
              ),
              title: Text(
                isWinner ? 'Vitória!' : 'Derrota',
                style: TextStyle(
                  color: isWinner ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, textAlign: TextAlign.center),
                  if (_iWantRematch && !_opponentWantsRematch) ...[
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Aguardando oponente aceitar...',
                          style: TextStyle(fontSize: 13, color: Colors.amber),
                        ),
                      ],
                    ),
                  ],
                  if (!_iWantRematch && _opponentWantsRematch) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'O oponente quer jogar novamente!',
                      style: TextStyle(fontSize: 13, color: Colors.greenAccent),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _backToMenu();
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Voltar ao Menu'),
                ),
                ElevatedButton.icon(
                  onPressed: _iWantRematch
                      ? null
                      : () {
                          setState(() => _iWantRematch = true);
                          setDialogState(() {});
                          _socketService.send({'type': 'rematch_request'});

                          if (_opponentWantsRematch) {
                            Navigator.pop(ctx);
                            _startRematch();
                          }
                        },
                  icon: const Icon(Icons.refresh),
                  label: Text(_iWantRematch ? 'Aguardando...' : 'Jogar Novamente'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Encerra a conexão socket, fecha o ServerSocket (se for host) e
  /// navega de volta à tela de conexão.
  void _backToMenu() {
    _dialogSetState = null;
    _socketService.dispose();
    widget.serverSocket?.close();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ConnectionScreen()),
    );
  }

  /// Reinicia todos os dados da partida para uma nova rodada, mantendo a
  /// mesma conexão socket. O jogador 1 (host) sempre começa a revanche.
  void _startRematch() {
    _dialogSetState = null;
    // Fecha o diálogo se ainda estiver aberto
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    setState(() {
      board = List.generate(kRows, (_) => List.filled(kCols, 0));
      phase = GamePhase.placement;
      currentTurn = 1;
      placedPlayer1 = 0;
      placedPlayer2 = 0;
      selectedRow = null;
      selectedCol = null;
      _iWantRematch = false;
      _opponentWantsRematch = false;

      statusMessage = currentTurn == myPlayer
          ? 'Sua vez — toque em uma casa para colocar sua peça'
          : 'Aguardando o oponente jogar...';
    });
  }

  /// Rola a lista do chat até a mensagem mais recente após um pequeno atraso
  /// para garantir que o widget já foi renderizado.
  void _scrollChatToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    int opponent = myPlayer == 1 ? 2 : 1;
    int myPieceCount = _countPieces(myPlayer);
    int opPieceCount = _countPieces(opponent);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dara — Jogador $myPlayer '
          '(${widget.isHost ? "Host" : "Cliente"})',
        ),
        actions: [
          if (phase != GamePhase.gameOver)
            TextButton.icon(
              onPressed: _surrender,
              icon: const Icon(Icons.flag, color: Colors.redAccent),
              label: const Text('Desistir',
                  style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: Column(
        children: [
          InfoBar(
            phase: phase,
            myPlayer: myPlayer,
            currentTurn: currentTurn,
            myPieces: myPieceCount,
            opPieces: opPieceCount,
            placedPlayer1: placedPlayer1,
            placedPlayer2: placedPlayer2,
            statusMessage: statusMessage,
            isError: statusIsError,
          ),

          Expanded(
            flex: 3,
            child: Center(
              child: BoardWidget(
                board: board,
                myPlayer: myPlayer,
                phase: phase,
                selectedRow: selectedRow,
                selectedCol: selectedCol,
                onCellTap: _onCellTap,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: ChatWidget(
              messages: chatMessages,
              chatController: _chatController,
              scrollController: _chatScrollController,
              onSend: _sendChat,
            ),
          ),
        ],
      ),
    );
  }

  /// Libera todos os recursos ao sair da tela: fecha o socket, o ServerSocket
  /// (se host) e os controllers de texto e scroll.
  @override
  void dispose() {
    _socketService.dispose();
    widget.serverSocket?.close();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }
}
