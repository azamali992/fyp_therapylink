part of 'chat_bloc.dart';

@immutable
abstract class ChatEvent {}

class ChatGenerateNewTextMessageEvent extends ChatEvent {
  final String inputMessage;
  final String conversationId;

  ChatGenerateNewTextMessageEvent({
    required this.inputMessage,
    required this.conversationId,
  });
}

class ChatLoadMessagesEvent extends ChatEvent {
  final String conversationId;

  ChatLoadMessagesEvent({required this.conversationId});
}
