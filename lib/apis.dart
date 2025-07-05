import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart'; // Dio for HTTP requests
import 'package:therapylink/utils/const.dart'; // API Key (ensure this is available)

class FirebaseApis {
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseAuth auth = FirebaseAuth.instance;

  // Create or retrieve a conversation document
  static Future<String> createConversation(String conversationId) async {
    try {
      DocumentReference conversationRef = firestore.collection('Conversations').doc(conversationId);

      // Check if the document already exists
      DocumentSnapshot snapshot = await conversationRef.get();

      if (!snapshot.exists) {
        await conversationRef.set({
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      return conversationRef.id; // Return the conversation ID
    } catch (e) {
      print("Error creating conversation: $e");
      return '';
    }
  }

  // Save a message (either from user or bot) to Firestore
  static Future<void> saveMessage(String conversationId, String sender, String messageContent) async {
    try {
      DocumentReference conversationRef = firestore.collection('Conversations').doc(conversationId);

      // Add the message to the 'Messages' subcollection within the conversation
      await conversationRef.collection('Messages').add({
        "Sender": sender, // "user" or "bot"
        "MessageContent": messageContent, // The actual content of the message
        "Timestamp": FieldValue.serverTimestamp(), // Automatically set the timestamp
      }).then((value) {
        print("Message saved successfully.");
      }).catchError((error) {
        print("Failed to save message: $error");
      });
    } catch (e) {
      print("Error saving message to Firestore: $e");
    }
  }

  // Retrieve all messages for a specific conversation
  static Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      QuerySnapshot snapshot = await firestore
          .collection('Conversations')
          .doc(conversationId)
          .collection('Messages')
          .orderBy('Timestamp', descending: false) // Order by timestamp
          .get();

      List<Map<String, dynamic>> messages = [];
      snapshot.docs.forEach((doc) {
        messages.add(doc.data() as Map<String, dynamic>);
      });

      return messages;
    } catch (e) {
      print("Error retrieving messages: $e");
      return [];
    }
  }

  // Example method to generate a bot response (replace with actual AI integration)
  static Future<String> getBotResponse(String userMessage, String conversationId) async {
    try {
      Dio dio = Dio();

      // Send the user's message to the AI API for response
      final response = await dio.post(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apikey",
        data: {
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": userMessage}
              ]
            }
          ],
          "systemInstruction": {
            "role": "user",
            "parts": [
              {
                "text":
                "It should give answers as a psychologist\nand keep answers like human and short. You are a professional therapist with a PhD."
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
        },
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        String botResponse =
        response.data['candidates'].first['content']['parts'].first['text'];

        // Save the bot's response to Firestore
        await saveMessage(conversationId, "bot", botResponse);

        return botResponse;
      } else {
        return "Error: Unable to get bot response";
      }
    } catch (e) {
      print("Error generating bot response: $e");
      return "Error";
    }
  }
}
