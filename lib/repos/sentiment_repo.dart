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
      'https://multilingsentiment.onrender.com/predict';

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

    final veryPositiveWords = [
      'excellent',
      'wonderful',
      'amazing',
      'awesome',
      'fantastic',
      'terrific',
      'delighted',
      'ecstatic',
      'thrilled',
      'overjoyed',
      'brilliant',
      'extraordinary',
      'exceptional',
      'magnificent',
    ];

    final positiveWords = [
      'good',
      'great',
      'happy',
      'glad',
      'pleased',
      'joy',
      'hope',
      'excited',
      'grateful',
      'thankful',
      'positive',
      'satisfied',
      'proud',
      'kush',
      'successful',
      'nice',
      'better',
      'cheerful',
      'content',
    ];

    final neutralWords = [
      'okay',
      'fine',
      'alright',
      'so-so',
      'neutral',
      'average',
      'moderate',
      'fair',
      'passable',
      'tolerable',
      'mediocre',
      'acceptable',
      'reasonable',
    ];

    final negativeWords = [
      'bad',
      'sad',
      'upset',
      'unhappy',
      'disappointed',
      'sorry',
      'regret',
      'worried',
      'negative',
      'frustrated',
      'annoyed',
      'poor',
      'fail',
      'dislike',
    ];

    final veryNegativeWords = [
      'terrible',
      'horrible',
      'hate',
      'angry',
      'anxious',
      'depressed',
      'miserable',
      'awful',
      'dreadful',
      'devastating',
      'appalling',
      'catastrophic',
      'dire',
      'tragic',
      'wretched',
    ];

    int veryPos = 0, pos = 0, neu = 0, neg = 0, veryNeg = 0;

    for (var w in veryPositiveWords) {
      if (RegExp(r'\b' + w + r'\b').hasMatch(normalized)) veryPos++;
    }
    for (var w in positiveWords) {
      if (RegExp(r'\b' + w + r'\b').hasMatch(normalized)) pos++;
    }
    for (var w in neutralWords) {
      if (RegExp(r'\b' + w + r'\b').hasMatch(normalized)) neu++;
    }
    for (var w in negativeWords) {
      if (RegExp(r'\b' + w + r'\b').hasMatch(normalized)) neg++;
    }
    for (var w in veryNegativeWords) {
      if (RegExp(r'\b' + w + r'\b').hasMatch(normalized)) veryNeg++;
    }

    print(
        'Local counts → very pos: $veryPos, pos: $pos, neu: $neu, neg: $neg, very neg: $veryNeg');

    // Determine the highest count
    int max = [veryPos, pos, neu, neg, veryNeg].reduce((a, b) => a > b ? a : b);

    if (max == veryPos && veryPos > 0) return 'very positive';
    if (max == pos && pos > 0) return 'positive';
    if (max == veryNeg && veryNeg > 0) return 'very negative';
    if (max == neg && neg > 0) return 'negative';
    if (max == neu && neu > 0) return 'neutral';

    // If no matches or tie, fallback to neutral
    return 'neutral';
  }

  /// Analyze the sentiment of [text], then save it under the signed-in user.
  /// Returns one of: 'very positive', 'positive', 'neutral', 'negative', 'very negative'
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
          data.containsKey('sentiment')) {
        sentiment = data['sentiment'] as String;
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
