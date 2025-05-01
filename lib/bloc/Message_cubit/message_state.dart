part of 'message_cubit.dart';

@immutable
sealed class MessageState {}

final class MessageInitial extends MessageState {}

class MessageUpdated extends MessageState {
  final Map<String, List<Map<String, String>>> messages;
  final Set<String> unreadIPs;

  MessageUpdated(this.messages, this.unreadIPs);
}
