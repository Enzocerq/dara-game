import 'dart:io';
import 'package:flutter/material.dart';
import 'game_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _ipController = TextEditingController(text: 'localhost');
  final _portController = TextEditingController(text: '9090');

  String _status = '';
  bool _connecting = false;

  Future<void> _hostGame() async {
    setState(() {
      _connecting = true;
      _status = 'Aguardando conexão na porta ${_portController.text}...';
    });

    try {
      int port = int.parse(_portController.text);

      ServerSocket serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        port,
      );

      Socket clientSocket = await serverSocket.first;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            socket: clientSocket,
            isHost: true,
            serverSocket: serverSocket,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Erro ao hospedar: $e';
        _connecting = false;
      });
    }
  }

  Future<void> _joinGame() async {
    setState(() {
      _connecting = true;
      _status = 'Conectando a ${_ipController.text}:${_portController.text}...';
    });

    try {
      int port = int.parse(_portController.text);

      Socket socket = await Socket.connect(_ipController.text, port);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            socket: socket,
            isHost: false,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Erro ao conectar: $e';
        _connecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dara - Conexão')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '◆ DARA ◆',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jogo de Estratégia Africano',
                style: TextStyle(fontSize: 16, color: Colors.brown.shade300),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.brown.shade900.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Alinhe 3 peças (horizontal/vertical) para capturar peças do '
                  'oponente. Vence quem reduzir o adversário a 2 peças!\n\n'
                  '• Fase 1 - Colocação: posicione suas 12 peças (sem formar linhas de 3)\n'
                  '• Fase 2 - Movimentação: mova peças para casas adjacentes\n'
                  '• Ao formar 3 em linha, capture uma peça do oponente',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Endereço IP do Host',
                  prefixIcon: Icon(Icons.computer),
                  border: OutlineInputBorder(),
                  helperText: 'Use "localhost" para jogar na mesma máquina',
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Porta',
                  prefixIcon: Icon(Icons.lan),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _connecting ? null : _hostGame,
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Hospedar Partida'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _connecting ? null : _joinGame,
                    icon: const Icon(Icons.login),
                    label: const Text('Conectar a Partida'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_connecting)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: CircularProgressIndicator(),
                ),
              Text(
                _status,
                style: const TextStyle(color: Colors.amber),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
