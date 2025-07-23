// lib/sentiment_repo.dart
// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:async';

// Firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SentimentRepo {
  // Your sentiment-analysis API endpoint
  static const String _endpoint =
      'https://sentiment-analysis-ubqy.onrender.com/detect_emotion';

  /// Saves one record into:
  ///   users/{uid}/sentiments/{autoId}
  static Future<void> _saveSentimentToFirestore({
    required String uid,
    required String text,
    required String sentiment,
  }) async {
    print('🔑 Saving sentiment for user $uid: $sentiment');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sentiments')
        .add({
      'text': text,
      'sentiment': sentiment,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('✅ Saved to users/$uid/sentiments');
  }

  /// Local fallback if the API totally fails
  static String _localSentimentAnalysis(String text) {
    final normalized = text.toLowerCase();

    final positiveWords = [
      'good', 'great', 'happy', 'excellent', 'wonderful',
      'amazing', 'love', 'enjoy', 'glad', 'pleased',
      'joy', 'hope', 'excited', 'grateful', 'thankful',
      'positive', 'awesome', 'fantastic', 'terrific',
      'delighted', 'satisfied', 'proud','kush' 'successful',
    ];
    final negativeWords = [
      'bad', 'sad', 'angry', 'upset', 'terrible',
      'horrible', 'hate', 'dislike', 'unhappy', 'disappointed',
      'sorry', 'regret', 'worried', 'anxious', 'negative',
      'depressed', 'frustrated', 'annoyed', 'miserable',
      'awful', 'poor', 'fail',
    ];

    int pos = 0, neg = 0;
    for (var w in positiveWords) {
      if (RegExp(r'\b' + w + r'\b').hasMatch(normalized)) pos++;
    }
    for (var w in negativeWords) {
      if (RegExp(r'\b' + w + r'\b').hasMatch(normalized)) neg++;
    }

    print('Local counts → pos: $pos, neg: $neg');
    if (pos > neg) return 'pos';
    if (neg > pos) return 'neg';
    return 'neu';
  }

  /// Analyze the sentiment of [text], then save it under the signed-in user.
  /// Returns one of: 'pos', 'neg', 'neu'
  static Future<String> analyzeSentiment(String text) async {
    print('📝 Analyzing sentiment for: "$text"');

    String sentiment;

    try {
      // 1) Call the remote API
      final response = await Dio().post(
        _endpoint,
        data: jsonEncode({'text': text}),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      print('🌐 API status: ${response.statusCode}');
      print('🌐 API raw data: ${response.data}');

      var data = response.data;
      if (data is String) data = jsonDecode(data);

      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['emotion'] is String) {
        sentiment = data['emotion'] as String;
        print('🎯 API returned: $sentiment');
      } else {
        throw Exception('Invalid API response');
      }
    } catch (e) {
      // 2) On any error, fallback locally
      print('⚠️ API error: $e');
      sentiment = _localSentimentAnalysis(text);
      print('🛠️ Fallback sentiment: $sentiment');
    }

    // 3) Save result under the current user
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _saveSentimentToFirestore(
          uid: user.uid,
          text: text,
          sentiment: sentiment,
        );
      } catch (e) {
        print('❌ Firestore write failed: $e');
      }
    } else {
      print('🚨 No user signed in—cannot save sentiment.');
    }

    return sentiment;
  }
}
