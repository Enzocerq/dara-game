import 'package:flutter/material.dart';

class ChatWidget extends StatelessWidget {
  final List<String> messages;
  final TextEditingController chatController;
  final ScrollController scrollController;
  final VoidCallback onSend;

  const ChatWidget({
    super.key,
    required this.messages,
    required this.chatController,
    required this.scrollController,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.brown.shade800,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: const Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 16),
                SizedBox(width: 8),
                Text('Chat', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma mensagem ainda...',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      bool isMe = messages[i].startsWith('Você');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          messages[i],
                          style: TextStyle(
                            color: isMe
                                ? Colors.lightBlueAccent
                                : Colors.orangeAccent,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatController,
                    decoration: InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.brown.shade600,
                  ),
                  child: IconButton(
                    onPressed: onSend,
                    icon: const Icon(Icons.send, size: 18),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
