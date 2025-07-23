part of 'chat_bloc.dart';

@immutable
sealed class ChatState {}

final class ChatInitial extends ChatState {}

final class ChatLoadingState extends ChatState {}

final class ChatSuccessState extends ChatState {
  final List<ChatMessageModel> messages;
  final bool isLoading;

  ChatSuccessState({
    required this.messages,
    this.isLoading = false,
  });

  ChatSuccessState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
  }) {
    return ChatSuccessState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final class ChatErrorState extends ChatState {
  final String error;
  ChatErrorState({required this.error});
}