import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:therapylink/models/chat_message_model.dart';

import '../apis.dart'; // Ensure this is imported for bot response generation

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final String conversationId; // conversationId passed when navigating to the screen

  // Initialize with conversationId
  ChatBloc({required this.conversationId}) : super(ChatSuccessState(messages: const [])) {
    on<ChatGenerateNewTextMessageEvent>(chatGenerateNewTextMessageEvent);
  }

  List<ChatMessageModel> messages = [];

  // The method that handles generating and saving messages to Firestore
  Future<FutureOr<void>> chatGenerateNewTextMessageEvent(
      ChatGenerateNewTextMessageEvent event, Emitter<ChatState> emit) async {
    // Add user message to the list
    messages.add(ChatMessageModel(
        role: "user", parts: [ChatPartModel(text: event.inputMessage)]));
    emit(ChatSuccessState(messages: messages));

    // Save the user's message to Firestore
    await FirebaseApis.saveMessage(conversationId, "user", event.inputMessage);

    // Generate the bot's response (this logic should only be executed once)
    String generatedText = await FirebaseApis.getBotResponse(event.inputMessage, conversationId);

    if (generatedText.isNotEmpty) {
      // Add the bot's response to the list
      messages.add(ChatMessageModel(
          role: 'bot', parts: [ChatPartModel(text: generatedText)]));

      // Emit the updated state with new messages
      emit(ChatSuccessState(messages: messages));

      // Save the bot's response to Firestore (do this once only)
      await FirebaseApis.saveMessage(conversationId, "bot", generatedText);
    }
  }
}
