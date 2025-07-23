import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:therapylink/models/chat_message_model.dart';
import 'package:therapylink/apis.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChatBloc({required this.userId}) : super(ChatInitial()) {
    on<ChatLoadMessagesEvent>(_onLoadMessages);
    on<ChatGenerateNewTextMessageEvent>(_onGenerateMessage);
  }

  Future<void> _onLoadMessages(
      ChatLoadMessagesEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoadingState());
    try {
      final messagesSnapshot = await _firestore
          .collection('users')
          .doc(event.conversationId)
          .collection('messages')
          .orderBy('timestamp')
          .get();

      final messages = messagesSnapshot.docs.map((doc) {
        return ChatMessageModel.fromMap(doc.data());
      }).toList();

      emit(ChatSuccessState(messages: messages, isLoading: false));
    } catch (e) {
      emit(ChatErrorState(error: e.toString()));
    }
  }

  Future<void> _onGenerateMessage(
      ChatGenerateNewTextMessageEvent event, Emitter<ChatState> emit) async {
    if (state is! ChatSuccessState) return;

    try {
      // Get current messages list
      final currentMessages =
          List<ChatMessageModel>.from((state as ChatSuccessState).messages);

      // Create and add user message
      final userMessage = ChatMessageModel(
        role: "user",
        parts: [ChatPartModel(text: event.inputMessage)],
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      currentMessages.add(userMessage);

      // First emit with just user message
      emit(ChatSuccessState(messages: currentMessages, isLoading: true));

      // Save user message to Firestore
      await _firestore
          .collection('users')
          .doc(event.conversationId)
          .collection('messages')
          .add(userMessage.toMap());

      // Get bot response
      try {
        print('[DEBUG] Getting bot response for: "${event.inputMessage}"');
        // Import FirebaseApis here if needed or use your own implementation
        final response =
            await _getBotResponse(event.inputMessage, event.conversationId);
        print('[DEBUG] Bot response received: "$response"');

        if (response.isNotEmpty) {
          // Create bot message
          final botMessage = ChatMessageModel(
            role: "model",
            parts: [ChatPartModel(text: response)],
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );

          // Add to messages and emit
          currentMessages.add(botMessage);
          emit(ChatSuccessState(messages: currentMessages, isLoading: false));

          // Save bot message to Firestore
          await _firestore
              .collection('users')
              .doc(event.conversationId)
              .collection('messages')
              .add(botMessage.toMap());
        } else {
          // If response is empty, just turn off loading state
          emit(ChatSuccessState(messages: currentMessages, isLoading: false));
        }
      } catch (e) {
        print('[ERROR] Failed to get bot response: $e');
        // Make sure to turn off loading state even if there's an error
        emit(ChatSuccessState(messages: currentMessages, isLoading: false));
      }
    } catch (e) {
      emit(ChatErrorState(error: e.toString()));
    }
  }

  // Helper method to get bot response using Hugging Face API
  Future<String> _getBotResponse(String message, String conversationId) async {
    try {
      print('[DEBUG] Calling Hugging Face API via FirebaseApis.getBotResponse');

      // Call the Hugging Face API and get response
      final response =
          await FirebaseApis.getBotResponse(message, conversationId);

      if (response.length > 50) {
        print(
            '[DEBUG] API response received: "${response.substring(0, 50)}..."');
      } else {
        print('[DEBUG] API response received: "$response"');
      }
      return response;
    } catch (e) {
      print('[ERROR] Error generating bot response from API: $e');
      return 'Sorry, I encountered an error while processing your message. Please try again.';
}
}
}