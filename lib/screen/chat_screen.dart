import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ping_chat/bloc/Message_cubit/message_cubit.dart';
import 'package:ping_chat/core/helper_funtions.dart';
import 'package:ping_chat/server.dart';

class ChatScreen extends StatefulWidget {
  final String peerIP;
  final Server? server;
  final String peerName;

  const ChatScreen({
    super.key,
    required this.peerIP,
    required this.peerName,
    this.server,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;

  Socket? _socket;

  @override
  void initState() {
    context.read<MessageCubit>().markAsRead(widget.peerIP);
    super.initState();
    _connectToServer();
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _connectToServer() async {
    try {
      if (_socket != null) {
        await _socket!.close();
      }
      _socket = await Socket.connect(widget.peerIP, 8080);
      log('Connected to ${widget.peerIP}');
    } catch (e) {
      log("Error connecting to server: $e");
    }
  }

  void _sendMessage(String message) {
    if (message.isNotEmpty) {
      if (_socket == null) {
        _connectToServer().then((_) {
          if (_socket != null) {
            _socket!.write('$message\n');
            if (!mounted) return;
            context.read<MessageCubit>().addMessage(
              widget.peerIP,
              message,
              isMe: true,
            );
            _scrollToBottom();
            _messageController.clear();
          }
        });
      } else {
        _socket!.add(utf8.encode('$message\n'));

        if (!mounted) return;
        context.read<MessageCubit>().addMessage(
          widget.peerIP,
          message,
          isMe: true,
        );
        _scrollToBottom();
        _messageController.clear();
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _socket?.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        context.read<MessageCubit>().markAsRead(widget.peerIP);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chat with ${widget.peerName}'),
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              context.read<MessageCubit>().markAsRead(widget.peerIP);
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios_new_sharp),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: BlocConsumer<MessageCubit, MessageState>(
                  listenWhen: (prev, curr) => curr is MessageUpdated,
                  listener: (context, state) {
                    if (state is MessageUpdated) {
                      final messages = state.messages[widget.peerIP] ?? [];
                      if (messages.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state is MessageUpdated) {
                      final messages = state.messages[widget.peerIP] ?? [];

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        reverse: false,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg['sender'] == 'You';
                          return Align(
                            alignment:
                                isMe
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                            child: GestureDetector(
                              onLongPress: () {
                                Clipboard.setData(
                                  ClipboardData(text: msg['text'] ?? ''),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied to clipboard'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
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
                                  color:
                                      isMe
                                          ? Colors.blueAccent
                                          : Colors.grey.shade300,
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
                                      msg['text'] ?? '',
                                      style: TextStyle(
                                        color:
                                            isMe
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatTime(DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 8,
                                        color:
                                            isMe
                                                ? Colors.white70
                                                : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.emoji_emotions_outlined),
                          onPressed: () {
                            setState(
                              () => _showEmojiPicker = !_showEmojiPicker,
                            );
                            if (!_showEmojiPicker) _focusNode.requestFocus();
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            onSubmitted: (message) => _sendMessage(message),
                            decoration: const InputDecoration(
                              hintText: 'Enter your message...',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed:
                              () => _sendMessage(_messageController.text),
                        ),
                      ],
                    ),
                    Offstage(
                      offstage: !_showEmojiPicker,
                      child: SizedBox(
                        height: 250,
                        child: EmojiPicker(
                          onEmojiSelected: (category, emoji) {
                            _messageController.text += emoji.emoji;
                            _messageController
                                .selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: _messageController.text.length,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
