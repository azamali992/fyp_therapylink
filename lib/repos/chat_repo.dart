
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:therapylink/models/chat_message_model.dart'; // Your model
import 'package:therapylink/utils/const.dart'; // API Key (ensure this is available)

class ChatRepo {
  // Method to generate a bot response and save messages to Firestore
  static Future<String> chatTextGenerationRepo(
      List<ChatMessageModel> previousMessages, String conversationId) async {
    try {
      Dio dio = Dio();

      // Send the previous messages to the bot API to get a response
      final response = await dio.post(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apikey",
          data: {
            "contents": previousMessages.map((e) => e.toMap()).toList(),
            "systemInstruction": {
              "role": "user",
              "parts": [
                {
                  "text":
                  "it should give answers as a psychologist\nand keep answer like human and short, remember you are a professional therapist with a PhD in it."
                }
              ]
            },
            "generationConfig": {
              "temperature": 1,
              "topK": 40,
              "topP": 0.95,
              "maxOutputTokens": 8192,
              "responseMimeType": "text/plain"
            }
          });

      // If the response is successful, get the bot response
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        String botResponse =
        response.data['candidates'].first['content']['parts'].first['text'];

        // Save the user's message and the bot's response to Firestore
        await saveMessageToFirestore(conversationId, "user", previousMessages.last.parts.first.text);
        await saveMessageToFirestore(conversationId, "bot", botResponse);

        return botResponse;
      } else {
        return "Error: Unable to get bot response";
      }
    } catch (e) {
      print("Error generating bot response: $e");
      return "Error";
    }
  }

  // Save a message (either from user or bot) to Firestore
  static Future<void> saveMessageToFirestore(
      String conversationId, String sender, String messageContent) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Reference to the conversation document using conversationId
      DocumentReference conversationRef = firestore.collection('Conversations').doc(conversationId);

      // Add the message to the conversation's Messages subcollection
      await conversationRef.collection('Messages').add({
        "Sender": sender, // "user" or "bot"
        "MessageContent": messageContent, // The actual content of the message
        "Timestamp": FieldValue.serverTimestamp(), // Automatically set the timestamp
      }).then((value) {
        print('Message saved to Firestore successfully!');
      }).catchError((error) {
        print('Failed to save message: $error');
      });
    } catch (e) {
      print("Error saving message to Firestore: $e");
    }
  }

  // Retrieve all messages for a conversation from Firestore
  static Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Conversations')
          .doc(conversationId)
          .collection('Messages')
          .orderBy('Timestamp', descending: false) // Order by timestamp
          .get();

      List<ChatMessageModel> messages = [];
      snapshot.docs.forEach((doc) {
        // Get each message's content and deserialize it to ChatMessageModel
        var messageContent = doc['MessageContent'];
        ChatMessageModel message = ChatMessageModel.fromJson(messageContent);
        messages.add(message);
      });

      return messages;
    } catch (e) {
      print("Error retrieving messages: $e");
      return [];
    }
  }
}
