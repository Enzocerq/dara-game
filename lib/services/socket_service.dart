import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Serviço de comunicação via TCP Socket.
/// Encapsula envio/recebimento de mensagens JSON delimitadas por \n.
class SocketService {
  final Socket socket;
  String _buffer = '';
  late StreamSubscription _subscription;

  /// Callback chamado quando uma mensagem JSON completa é recebida.
  void Function(Map<String, dynamic> msg)? onMessage;

  /// Callback chamado quando ocorre um erro no socket.
  void Function(dynamic error)? onError;

  /// Callback chamado quando a conexão é encerrada.
  void Function()? onDone;

  SocketService(this.socket);

  /// Inicia a escuta do socket.
  void startListening() {
    _subscription = socket.listen(
      (List<int> data) {
        _buffer += utf8.decode(data);

        while (_buffer.contains('\n')) {
          int idx = _buffer.indexOf('\n');
          String rawMsg = _buffer.substring(0, idx);
          _buffer = _buffer.substring(idx + 1);

          try {
            Map<String, dynamic> msg = json.decode(rawMsg);
            onMessage?.call(msg);
          } catch (e) {
            debugPrint('Erro ao processar mensagem: $e');
          }
        }
      },
      onError: (e) => onError?.call(e),
      onDone: () => onDone?.call(),
    );
  }

  /// Envia uma mensagem JSON para o outro jogador.
  void send(Map<String, dynamic> msg) {
    try {
      String encoded = '${json.encode(msg)}\n';
      socket.add(utf8.encode(encoded));
    } catch (e) {
      debugPrint('Erro ao enviar mensagem: $e');
    }
  }

  /// Encerra a escuta e fecha o socket.
  void dispose() {
    _subscription.cancel();
    socket.close();
  }
}
