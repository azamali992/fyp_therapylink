// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:async';

class SentimentRepo {
  // Track API calls to prevent rate limiting
  static DateTime _lastApiCall =
      DateTime.now().subtract(const Duration(minutes: 1));
  static int _apiCallsInLastMinute = 0;
  static const int _maxCallsPerMinute = 5;

  // Simple local sentiment analysis as fallback
  static String _localSentimentAnalysis(String text) {
    text = text.toLowerCase();

    // Define positive and negative word lists
    final positiveWords = [
      'good',
      'great',
      'happy',
      'excellent',
      'wonderful',
      'amazing',
      'love',
      'enjoy',
      'glad',
      'pleased',
      'joy',
      'hope',
      'excited',
      'grateful',
      'thankful',
      'positive',
      'awesome',
      'fantastic',
      'terrific',
      'delighted',
      'satisfied',
      'proud',
    ];

    final negativeWords = [
      'bad',
      'sad',
      'angry',
      'upset',
      'terrible',
      'horrible',
      'hate',
      'dislike',
      'unhappy',
      'disappointed',
      'sorry',
      'regret',
      'worried',
      'anxious',
      'negative',
      'depressed',
      'frustrated',
      'annoyed',
      'miserable',
      'awful',
      'poor',
      'fail',
    ];

    int positiveCount = 0;
    int negativeCount = 0;

    for (final word in positiveWords) {
      if (text.contains(word)) {
        positiveCount++;
      }
    }

    for (final word in negativeWords) {
      if (text.contains(word)) {
        negativeCount++;
      }
    }

    if (positiveCount > negativeCount) {
      return 'pos';
    } else if (negativeCount > positiveCount) {
      return 'neg';
    } else {
      return 'neu';
    }
  }

  static Future<String> analyzeSentiment(String text) async {
    // First check if we should use the API or fallback
    final now = DateTime.now();
    final timeSinceLastCall = now.difference(_lastApiCall);

    // Reset counter if it's been more than a minute
    if (timeSinceLastCall.inSeconds >= 60) {
      _apiCallsInLastMinute = 0;
    }

    // If we've made too many calls, use the fallback
    if (_apiCallsInLastMinute >= _maxCallsPerMinute) {
      print('Rate limit reached, using local sentiment analysis');
      return _localSentimentAnalysis(text);
    }

    // Track this API call
    _lastApiCall = now;
    _apiCallsInLastMinute++;

    try {
      final dio = Dio();

      // Add retry logic
      String result = '';
      Exception? lastError;

      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          print('Making API request attempt ${attempt + 1}');

          final response = await dio.post(
            'https://sentiment-analysis-ubqy.onrender.com/detect_emotion',
            data: jsonEncode({'text': text}),
            options: Options(
              headers: {'Content-Type': 'application/json'},
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

          print('Sentiment API status: ${response.statusCode}');
          print('Sentiment API raw data: ${response.data}');

          dynamic data = response.data;
          if (data is String) {
            try {
              data = jsonDecode(data);
            } catch (e) {
              print('Failed to decode response string: $e');
              throw Exception('Failed to decode response');
            }
          }

          if (response.statusCode == 200 &&
              data != null &&
              data is Map<String, dynamic>) {
            final emotion = data['emotion'];
            if (emotion != null && emotion is String && emotion.isNotEmpty) {
              return emotion;
            }
          }

          // If we got here, something was wrong with the response
          throw Exception('Invalid or missing emotion in response');
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          print('Attempt ${attempt + 1} failed: $e');

          // Wait before next retry, with exponential backoff
          if (attempt < 2) {
            // Only wait if we're going to retry
            final waitTime = Duration(milliseconds: 500 * (attempt + 1));
            print('Waiting ${waitTime.inMilliseconds}ms before retry');
            await Future.delayed(waitTime);
          }
        }
      }

      // If all retries failed, use local analysis
      print('All API attempts failed, using local sentiment analysis');
      return _localSentimentAnalysis(text);
    } catch (e) {
      print('Sentiment API error: $e');
      return _localSentimentAnalysis(text);
    }
  }
}
