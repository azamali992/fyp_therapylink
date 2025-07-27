import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';

class SummaryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch chats and generate summary for current user
  static Future<String> generateChatSummary({
    int messageLimit = 50,
    String summaryType =
        'general', // Options: 'general', 'therapeutic', 'progress'
  }) async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      return await generateSummaryForUser(
        userId: user.uid,
        messageLimit: messageLimit,
        summaryType: summaryType,
      );
    } catch (e) {
      print('Error generating summary: $e');
      return 'Failed to generate summary. Please try again later.';
    }
  }

  // Generate summary for a specific user (can be used by professionals)
  static Future<String> generateSummaryForUser({
    required String userId,
    int messageLimit = 50,
    String summaryType = 'general',
  }) async {
    try {
      // Fetch recent messages
      final messages = await _fetchRecentMessages(userId, messageLimit);
      if (messages.isEmpty) {
        return 'Not enough conversation history to generate a summary.';
      }

      // Format messages for the Gemini API
      final formattedConversation = _formatConversationForSummary(messages);

      // Generate summary using Gemini
      final summary =
          await _generateSummaryWithGemini(formattedConversation, summaryType);

      // Save summary to Firestore
      await _saveSummaryToFirestore(userId, summary, summaryType);

      return summary;
    } catch (e) {
      print('Error generating summary: $e');
      return 'Failed to generate summary. Please try again later.';
    }
  }

  // Fetch recent messages from Firestore
  static Future<List<Map<String, dynamic>>> _fetchRecentMessages(
      String userId, int limit) async {
    try {
      // Query messages from Firebase
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      // Convert to a simple list of messages
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'role': data['role'] ?? 'unknown',
          'text': data['parts']?[0]['text'] ?? '',
          'timestamp': data['timestamp'] ?? Timestamp.now(),
        };
      }).toList();
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  // Format conversation for the Gemini API
  static String _formatConversationForSummary(
      List<Map<String, dynamic>> messages) {
    // Reverse to get chronological order
    final chronologicalMessages = messages.reversed.toList();

    StringBuffer conversation = StringBuffer();
    conversation.writeln("Conversation History:");

    for (var message in chronologicalMessages) {
      final role = message['role'] == 'user' ? 'User' : 'AI Therapist';
      final content = message['text'];
      conversation.writeln("$role: $content");
    }

    return conversation.toString();
  }

  // Generate summary using Firebase AI with Gemini
  static Future<String> _generateSummaryWithGemini(
    String conversation,
    String summaryType,
  ) async {
    try {
      // Initialize Firebase AI with Gemini model
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
      );

      // Create prompt based on summary type
      String promptText;
      switch (summaryType) {
        case 'therapeutic':
          promptText = '''
You are an expert psychological summarizer. Based on the following conversation between a user and an AI therapist:

$conversation

Please provide a therapeutic summary that includes:
1. Key emotional themes identified in the conversation
2. Main challenges or issues the user is facing
3. Progress made during the conversation
4. Potential therapeutic approaches that might benefit the user


Format your response in clear, concise  and 1 paragraphs.
''';
          break;

        case 'progress':
          promptText = '''
You are an expert in tracking therapeutic progress. Based on the following conversation between a user and an AI therapist:

$conversation

Please provide a progress summary that includes:
1. Baseline emotional state at the beginning of conversations
2. Changes in emotional tone throughout the conversation 
3. Key breakthroughs or insights the user had
4. Specific progress indicators observed
5. Areas that still need attention


Format your response in clear, concise and 1 paragraphs.
''';
          break;

        case 'general':
        default:
          promptText = '''
You are an expert conversation summarizer. Based on the following conversation between a user and an AI therapist:

$conversation

Please provide a concise summary that captures:
1. Main topics discussed
2. Key points made by both parties
3. Any decisions or conclusions reached
4. Overall tone and nature of the conversation

Keep your summary clear, objective, and under 250 words.
''';
      }

      // Create the message content
      final message = Content('user', [TextPart(promptText)]);

      // Start chat and send message
      final chat = model.startChat();
      final response = await chat.sendMessage(message);

      return response.text ?? 'Unable to generate summary.';
    } catch (e) {
      print('Error generating summary with Firebase AI: $e');
      return 'Unable to generate summary. API error occurred.';
    }
  }

  // Save summary to Firestore
  static Future<void> _saveSummaryToFirestore(
    String userId,
    String summary,
    String summaryType,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('summaries')
          .add({
        'summary': summary,
        'type': summaryType,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving summary: $e');
    }
  }

  // Get the latest summary for a user
  static Future<String?> getLatestSummary(String userId,
      {String summaryType = 'therapeutic'}) async {
    try {
      final summaryMap =
          await getLatestSummaryDocument(userId, summaryType: summaryType);
      return summaryMap?['summary'] as String?;
    } catch (e) {
      print('Error getting latest summary: $e');
      return null;
    }
  }

  // Get the full summary document including metadata
  static Future<Map<String, dynamic>?> getLatestSummaryDocument(
    String userId, {
    String summaryType = 'therapeutic',
  }) async {
    try {
      // Use the same path as in _saveSummaryToFirestore
      final summariesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('summaries')
          .where('type', isEqualTo: summaryType)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (summariesSnapshot.docs.isNotEmpty) {
        final data = summariesSnapshot.docs.first.data();
        // Add the document ID to the data
        data['id'] = summariesSnapshot.docs.first.id;
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching latest summary document: $e');
      return null;
    }
  }

  // Save a summary to Firestore
  static Future<bool> saveSummary(
      String userId, String summary, String summaryType) async {
    try {
      // Use the same path as in _saveSummaryToFirestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('summaries')
          .add({
        'summary': summary,
        'type': summaryType,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error saving summary: $e');
      return false;
    }
  }
}
