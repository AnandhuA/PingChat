import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ping_chat/core/helper_funtions.dart';
import 'package:ping_chat/models/chat_model.dart';
import 'package:ping_chat/server.dart';

class ChatScreen extends StatefulWidget {
  final String peerIP;
  final Server? server;
  final String peerName;
  final List<String> message;

  const ChatScreen({
    super.key,
    required this.peerIP,
    required this.peerName,
    this.server,
    required this.message,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  Socket? _socket;

  @override
  void initState() {
    for (String msg in widget.message) {
      _messages.add(
        ChatMessage(
          sender: widget.peerName,
          text: msg,
          timestamp: DateTime.now(),
        ),
      );
    }

    super.initState();
    _connectToServer();
    _reciveMessage();
  }

  Future<void> _connectToServer() async {
    try {
      _socket = await Socket.connect(widget.peerIP, 8080);
      log('Connected to ${widget.peerIP}');
    } catch (e) {
      log("Error connecting to server: $e");
    }
  }

  void _sendMessage(String message) {
    if (message.isNotEmpty && _socket != null) {
      _socket!.write('$message\n');
      if (!mounted) return;
      setState(() {
        // _messages.add('You: $message');
        _messages.add(
          ChatMessage(sender: 'You', text: message, timestamp: DateTime.now()),
        );
      });
      _messageController.clear();
    }
  }

  void _reciveMessage() {
    widget.server!.onMessageReceived = (message) {
      log("Message from client: $message");
      if (!mounted) return;
      setState(() {
        // _messages.add('${widget.peerName}: $message');
        _messages.add(
          ChatMessage(
            sender: widget.peerName,
            text: message,
            timestamp: DateTime.now(),
          ),
        );
      });
    };
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedMessages =
        _messages..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.peerName}')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                reverse: true,
                itemCount: sortedMessages.length,
                itemBuilder: (context, index) {
                  final msg = sortedMessages[index];
                  final isMe = msg.sender == 'You';

                  return Align(
                    alignment:
                        isMe ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blueAccent : Colors.grey.shade300,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(isMe ? 0 : 12),
                          bottomRight: Radius.circular(isMe ? 12 : 0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatTime(msg.timestamp),
                            style: TextStyle(
                              fontSize: 8,
                              color: isMe ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (v) => _sendMessage(v),
                      decoration: const InputDecoration(
                        hintText: 'Enter your message...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
