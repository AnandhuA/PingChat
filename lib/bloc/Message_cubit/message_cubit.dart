import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'message_state.dart';

class MessageCubit extends Cubit<MessageState> {
  final Map<String, List<Map<String, String>>> _messages = {};
  final Set<String> _unread = {};

  MessageCubit() : super(MessageInitial());

  void addMessage(String ip, String message, {bool isMe = false}) {
    _messages.putIfAbsent(ip, () => []);
    _messages[ip]!.add({'sender': isMe ? 'You' : 'Peer', 'text': message});
    if (!isMe) _unread.add(ip);
    emit(MessageUpdated(Map.from(_messages), Set.from(_unread)));
  }

  void markAsRead(String ip) {
    _unread.remove(ip);
    emit(MessageUpdated(Map.from(_messages), Set.from(_unread)));
  }

  bool hasUnread(String ip) => _unread.contains(ip);
}
