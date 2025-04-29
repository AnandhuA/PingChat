import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
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
  late List<String> _messages;

  Socket? _socket;

  @override
  void initState() {
    _messages = widget.message;
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
      setState(() {
        _messages.add('You: $message');
      });
      _messageController.clear();
    }
  }

  void _reciveMessage() {
    // log("reeee");
    widget.server!.onMessageReceived = (message) {
      log("Message from client: $message");
      setState(() {
        _messages.add('${widget.peerName}: $message');
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
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.peerName}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_messages[index]));
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
    );
  }
}
