import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
// contains your Gemini API key

class FirebaseApis {
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseAuth auth = FirebaseAuth.instance;

  // Save message under logged-in user
  static Future<void> saveMessage(
      String userId, String sender, String messageContent) async {
    try {
      DocumentReference userRef = firestore.collection('users').doc(userId);

      await userRef.collection('messages').add({
        "Sender": sender,
        "MessageContent": messageContent,
        "Timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving message: $e");
    }
  }

  // Load messages for this user
  static Future<List<Map<String, dynamic>>> getMessages(String userId) async {
    try {
      QuerySnapshot snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('messages')
          .orderBy('Timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error retrieving messages: $e");
      return [];
    }
  }

  // Call Hugging Face API and save response
  static Future<String> getBotResponse(
      String userMessage, String userId) async {
    try {
      // Configure Dio with proper timeouts
      Dio dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
      ));

      // Format request based on successful Postman test
      final response = await dio.post(
        "https://huggingfacerag.onrender.com/predict",
        data: {"message": userMessage},
      );

      if (response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        // Extract just the "response" field from the JSON
        String botResponse;

        if (response.data is Map && response.data['response'] != null) {
          // If the response is a map and has a 'response' field, extract it
          botResponse = response.data['response'].toString();
        } else {
          // Otherwise use the entire response data
          botResponse = response.data.toString();

          // Clean up the response if needed
          if (botResponse.startsWith('"') && botResponse.endsWith('"')) {
            botResponse = botResponse.substring(1, botResponse.length - 1);
          }
        }

        // Replace escaped quotes if any
        botResponse = botResponse.replaceAll('\\"', '"');

        await saveMessage(userId, "bot", botResponse);
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