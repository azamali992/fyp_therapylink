import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:therapylink/bloc/chat_bloc.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/repos/sentiment_repo.dart';
import 'package:therapylink/Views/stress_relieving.dart';
import 'package:therapylink/Views/maps/map 2.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final TextEditingController textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatBloc chatBloc;
  late String userId;
  String _username = "User";
  // Add this property to store the last sentiment
  String _currentSentiment = 'Unknown';

  // Add these new variables
  int _consecutiveNegativeCount = 0;
  bool _hasShownStressPopup = false; // To prevent showing popup multiple times
  bool _hasVisitedRelaxationPage =
      false; // Track if user has ever visited relaxation page

  // Add these variables for sentiment scoring
  List<int> _recentSentimentScores = [];
  int _totalSentimentScore =
      0; // Total accumulated sentiment score up to 30 points
  final int _maxTotalScore = 30; // Maximum limit for total score
  final int _stressThreshold = 10; // Threshold to suggest relaxation exercises
  final int _minChatsBeforeRedirect =
      5; // Minimum chats before checking  @override
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      // Get ChatBloc from BlocProvider
      chatBloc = BlocProvider.of<ChatBloc>(context, listen: false);
      chatBloc.add(ChatLoadMessagesEvent(conversationId: userId));
      _retrieveUsername();
      _loadLastSentiment(); // Add this line to load the last sentiment
    }

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _showIntroDialog();
    // });
  }

  // Add this new method to load the last sentiment from Firestore
  Future<void> _loadLastSentiment() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load the flag for visited relaxation page
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          setState(() {
            _hasVisitedRelaxationPage =
                userData['hasVisitedRelaxationPage'] ?? false;
          });
        }

        // Query the last sentiment document, ordered by timestamp
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('sentiments')
            .orderBy('timestamp', descending: true)
            .limit(_minChatsBeforeRedirect) // Get last 5 sentiments
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Load most recent sentiment for display
          final lastSentimentData = querySnapshot.docs.first.data();
          setState(() {
            _currentSentiment = lastSentimentData['sentiment'] ?? 'Unknown';
          });
          print('Last sentiment loaded: $_currentSentiment');

          // Initialize recent sentiment scores and calculate total score
          List<int> recentScores = [];
          int totalScore = 0;

          for (var doc in querySnapshot.docs) {
            final sentiment = doc.data()['sentiment'] as String? ?? '';
            int score = 0;

            // Updated scoring system for the new 5-level sentiment values
            if (sentiment.toLowerCase() == 'very positive') {
              score = -3; // Very positive greatly reduces stress score
            } else if (sentiment.toLowerCase() == 'positive') {
              score = -2; // Positive reduces stress score
            } else if (sentiment.toLowerCase() == 'neutral') {
              score = 0; // Neutral doesn't affect stress score
            } else if (sentiment.toLowerCase() == 'negative') {
              score = 2; // Negative increases stress score
            } else if (sentiment.toLowerCase() == 'very negative') {
              score = 3; // Very negative greatly increases stress score
            } else if (sentiment.toLowerCase() == 'pos') {
              score =
                  -2; // Handle legacy 'pos' values for backward compatibility
            } else if (sentiment.toLowerCase() == 'neg') {
              score =
                  2; // Handle legacy 'neg' values for backward compatibility
            } else if (sentiment.toLowerCase() == 'neu') {
              score =
                  0; // Handle legacy 'neu' values for backward compatibility
            }

            recentScores.add(score);
            totalScore += score;
          }

          // Cap total score at _maxTotalScore
          totalScore = totalScore.clamp(0, _maxTotalScore);

          // Reverse to maintain chronological order
          recentScores = recentScores.reversed.toList();

          setState(() {
            _recentSentimentScores = recentScores;
            _totalSentimentScore = totalScore;
          });
        }
      }
    } catch (e) {
      print('Error loading last sentiment: $e');
    }
  }

  Future<void> _analyzeSentiment(String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    final sentiment = await SentimentRepo.analyzeSentiment(text);
    final normalizedSentiment = sentiment.toLowerCase().trim();

    // Assign score based on sentiment
    int sentimentScore = 0; // default for neutral

    // Updated scoring system for the new 5-level sentiment values
    if (normalizedSentiment == 'very positive') {
      sentimentScore = -3; // Very positive greatly reduces stress score
    } else if (normalizedSentiment == 'positive' ||
        normalizedSentiment == 'pos') {
      sentimentScore = -2; // Positive reduces stress score
    } else if (normalizedSentiment == 'neutral' ||
        normalizedSentiment == 'neu') {
      sentimentScore = 0; // Neutral doesn't affect stress score
    } else if (normalizedSentiment == 'negative' ||
        normalizedSentiment == 'neg') {
      sentimentScore = 2; // Negative increases stress score
    } else if (normalizedSentiment == 'very negative') {
      sentimentScore = 3; // Very negative greatly increases stress score
    }

    // Add score to recent scores list
    _recentSentimentScores.add(sentimentScore);

    // Update total sentiment score
    _totalSentimentScore += sentimentScore;
    // Cap total score between 0 and max
    _totalSentimentScore = _totalSentimentScore.clamp(0, _maxTotalScore);

    print(
        'Current sentiment score: $sentimentScore, Total score: $_totalSentimentScore');

    // Keep only the last 5 sentiment scores
    if (_recentSentimentScores.length > _minChatsBeforeRedirect) {
      _recentSentimentScores.removeAt(0);
    }

    // Check if total score reaches max value (30) - severe stress case
    if (_totalSentimentScore >= _maxTotalScore) {
      _hasShownStressPopup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Navigate to appointment booking section in map 2.dart
        _showSevereStressPopup(); // Show popup for severe stress case
      });
    }
    // Check if total score exceeds stress threshold but less than max
    // Only show if user has never visited relaxation page
    else if (_totalSentimentScore >= _stressThreshold &&
        !_hasShownStressPopup &&
        !_hasVisitedRelaxationPage) {
      _hasShownStressPopup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStressReliefPopup(); // Show stress relief popup
      });
    }
    // // If score is very low (very positive emotions), show positive feedback
    // else if (_totalSentimentScore <= 2 &&
    //     _recentSentimentScores.length >= _minChatsBeforeRedirect &&
    //     !_hasShownStressPopup) {
    //   _hasShownStressPopup = true;
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _showPositiveFeedbackPopup(); // Show positive feedback
    //   });
    // }

    setState(() {
      _currentSentiment = sentiment;

      // Track consecutive negative sentiments (keep this for the stress relief popup)
      if (normalizedSentiment == 'neg' ||
          normalizedSentiment == 'negative' ||
          normalizedSentiment == 'very negative') {
        _consecutiveNegativeCount++;
        print('Consecutive negative count: $_consecutiveNegativeCount');

        // Show stress relief popup if reached threshold and not shown yet
        // Only show if user has never visited relaxation page
        if (_consecutiveNegativeCount >= 5 &&
            !_hasShownStressPopup &&
            !_hasVisitedRelaxationPage) {
          _hasShownStressPopup = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showStressReliefPopup();
          });
        }
      } else {
        // Reset counter if sentiment is not negative or very negative
        _consecutiveNegativeCount = 0;
        _hasShownStressPopup =
            false; // Reset popup flag when sentiment improves
      }
    });

    // Save the sentiment to Firestore for mood analysis
    await _saveSentimentToFirestore(normalizedSentiment);
  }

  // Helper method to save relaxation page visit status to Firestore
  Future<void> _saveRelaxationPageVisit() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'hasVisitedRelaxationPage': true,
        });
      }
    } catch (e) {
      print('Error saving relaxation page visit status: $e');
    }
  }

  // Add this helper method to save sentiments to Firestore
  Future<void> _saveSentimentToFirestore(String sentiment) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Calculate score
        int sentimentScore = 0;
        if (sentiment.toLowerCase() == 'pos' ||
            sentiment.toLowerCase() == 'positive') {
          sentimentScore = -2;
        } else if (sentiment.toLowerCase() == 'neg' ||
            sentiment.toLowerCase() == 'negative') {
          sentimentScore = 2;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('sentiments')
            .add({
          'sentiment': sentiment,
          'sentiment_score': sentimentScore, // Add this line
          'timestamp': FieldValue.serverTimestamp(),
          'message_count': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error saving sentiment to Firestore: $e');
    }
  }

  // void _showIntroDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(16),
  //         ),
  //         backgroundColor: AppColors.backgroundGradientStart,
  //         title: const Text(
  //           "TherapyLink: Meet Your AI Psychologist",
  //           style: TextStyle(
  //             fontWeight: FontWeight.bold,
  //             color: Colors.white,
  //           ),
  //         ),
  //         content: const Text(
  //           "Hello! I'm your AI Psychologist, here to listen, support, and guide you. Feel free to share your thoughts, and I'll do my best to help you on your journey.",
  //           style: TextStyle(color: Color.fromARGB(214, 235, 220, 16)),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child:
  //                 const Text("Got it", style: TextStyle(color: Colors.white)),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Future<void> _retrieveUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['username'] != null) {
            setState(() {
              _username = userData['username'];
            });
          }
        }
      }
    } catch (e) {
      print('Error retrieving username from Firestore: $e');
      // Keep default "User" if there's an error
    }
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Analyze sentiment before sending the message
    await _analyzeSentiment(message.trim());

    chatBloc.add(ChatGenerateNewTextMessageEvent(
      inputMessage: message.trim(),
      conversationId: userId,
    ));
    textEditingController.clear();
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(12),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              "Psychologist",
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
              color: const Color.fromARGB(255, 74, 20, 140),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.9),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Thinking...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: CustomAppBar(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundGradientStart,
              Color.fromARGB(255, 55, 13, 104),
              AppColors.backgroundGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Sentiment indicator at the top
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _getSentimentColor().withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getSentimentColor().withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getSentimentEmoji(),
                    style: const TextStyle(fontSize: 26),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sentiment: ${_getSentimentText()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                bloc: chatBloc,
                builder: (context, state) {
                  if (state is ChatSuccessState) {
                    final messages = state.messages;

                    // Start with latest messages visible
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length + (state.isLoading ? 1 : 0),
                      reverse: true, // Show newest messages at the bottom
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, reversedIndex) {
                        final index = messages.length - reversedIndex - 1;

                        // Show loading indicator as the first item when waiting for API response
                        if (state.isLoading && reversedIndex == 0) {
                          return _buildLoadingIndicator();
                        }

                        if (index < 0) return const SizedBox.shrink();

                        final message = messages[index];
                        final isUser = message.role == "user";
                        final timestamp = DateFormat('hh:mm a').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                message.timestamp));

                        // Add this padding to the Column widget that contains each message
                        return Padding(
                          padding: EdgeInsets.only(
                            left: isUser
                                ? 50.0
                                : 16.0, // Less padding on user's side, more on AI's side
                            right: isUser
                                ? 16.0
                                : 50.0, // Less padding on AI's side, more on user's side
                          ),
                          child: Column(
                            crossAxisAlignment: isUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isUser)
                                      Container(
                                        width: 18,
                                        height: 18,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromARGB(255, 121, 40, 202),
                                              Color.fromARGB(255, 95, 10, 180),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.psychology,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      isUser ? _username : "Psychologist",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isUser
                                            ? Colors.grey[300]
                                            : const Color.fromARGB(
                                                255, 220, 200, 255),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(isUser ? 16 : 0),
                                    topRight: Radius.circular(isUser ? 0 : 16),
                                    bottomLeft: const Radius.circular(16),
                                    bottomRight: const Radius.circular(16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  color: isUser
                                      ? const Color.fromARGB(255, 106, 27, 154)
                                      : const Color.fromARGB(255, 74, 20, 140),
                                ),
                                child: Text(
                                  message.parts.first.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12, top: 2),
                                child: Text(
                                  timestamp,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else if (state is ChatLoadingState) {
                    // Show full screen loader for initial loading
                    return const Center(
                        child: CircularProgressIndicator(
                      color: Colors.white,
                    ));
                  } else if (state is ChatErrorState) {
                    return Center(
                      child: Text(
                        state.error,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return const Center(
                      child: CircularProgressIndicator(
                    color: Colors.white,
                  ));
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: textEditingController,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 16),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          hintText: "Type your message...",
                          hintStyle:
                              TextStyle(color: Colors.grey[500], fontSize: 15),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 1.5),
                          ),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(30),
                    color: Theme.of(context).primaryColor,
                    child: InkWell(
                      onTap: () => _sendMessage(textEditingController.text),
                      borderRadius: BorderRadius.circular(30),
                      splashColor: Colors.purple[100],
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for sentiment display
  Color _getSentimentColor() {
    final s = _currentSentiment.toLowerCase().trim();
    if (s == 'very positive') {
      return Colors.green.shade700; // Darker green for very positive
    } else if (s == 'pos' || s == 'positive') {
      return Colors.green;
    } else if (s == 'very negative') {
      return Colors.red.shade900; // Darker red for very negative
    } else if (s == 'neg' || s == 'negative') {
      return Colors.red;
    } else if (s == 'neu' || s == 'neutral') {
      return const Color.fromARGB(255, 58, 9, 172);
    }
    return const Color.fromARGB(255, 11, 198, 231);
  }

  String _getSentimentEmoji() {
    final s = _currentSentiment.toLowerCase().trim();
    if (s == 'very positive') {
      return '😄'; // Big smile for very positive
    } else if (s == 'pos' || s == 'positive') {
      return '😊';
    } else if (s == 'very negative') {
      return '😭'; // Crying for very negative
    } else if (s == 'neg' || s == 'negative') {
      return '😢';
    } else if (s == 'neu' || s == 'neutral') {
      return '😐';
    }
    return '🤔';
  }

  String _getSentimentText() {
    final s = _currentSentiment.toLowerCase().trim();
    if (s == 'very positive') {
      return 'Very Positive';
    } else if (s == 'pos' || s == 'positive') {
      return 'Positive';
    } else if (s == 'very negative') {
      return 'Very Negative';
    } else if (s == 'neg' || s == 'negative') {
      return 'Negative';
    } else if (s == 'neu' || s == 'neutral') {
      return 'Neutral';
    }
    return _currentSentiment;
  }

  void _showStressReliefPopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.backgroundGradientStart,
          title: const Row(
            children: [
              Text(
                '🧘‍♀️',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Time to Relax',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'I\'ve noticed you might be feeling stressed. Would you like to try some relaxation exercises to help you feel better?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset popup flag but keep other variables
                setState(() {
                  _consecutiveNegativeCount = 0;
                  _hasShownStressPopup = false;
                  // Note: we don't reset _hasVisitedRelaxationPage here
                });
              },
              child: const Text(
                'Not Now',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to stress relief page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StressRelievingPage(),
                  ),
                ).then((_) {
                  // Reset counter and reduce stress score after visiting stress relief page
                  setState(() {
                    _consecutiveNegativeCount = 0;
                    _hasShownStressPopup = false;
                    _hasVisitedRelaxationPage =
                        true; // Set this flag to true once user visits relaxation page
                    _saveRelaxationPageVisit(); // Save this status to Firebase
                    // Reduce stress score by half after doing relaxation exercises
                    _totalSentimentScore = (_totalSentimentScore / 2).round();
                  });
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.backgroundGradientStart,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Yes, Help Me Relax',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSevereStressPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.backgroundGradientStart,
          title: const Row(
            children: [
              Text(
                '⚠️',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Immediate Support Needed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Your stress level is very high. We recommend booking an appointment with a therapist for professional support. Would you like to see available appointments?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset flags but keep the score
                setState(() {
                  _consecutiveNegativeCount = 0;
                  _hasShownStressPopup = false;
                });
              },
              child: const Text(
                'Not Now',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to map 2.dart for appointment booking
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MapScreen(),
                  ),
                ).then((_) {
                  // Reset after visiting appointment page
                  setState(() {
                    _consecutiveNegativeCount = 0;
                    _hasShownStressPopup = false;
                    // Reduce stress score slightly after scheduling appointment
                    _totalSentimentScore = (_totalSentimentScore * 0.7).round();
                  });
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.backgroundGradientStart,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Book Appointment',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPositiveFeedbackPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.backgroundGradientStart,
          title: const Row(
            children: [
              Text(
                '🎉',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Great Progress!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'You\'ve been maintaining a very positive outlook! Would you like to see your mood analysis to track your progress?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset the flag since user dismissed
                setState(() {
                  _hasShownStressPopup = false;
                });
              },
              child: const Text(
                'Not Now',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to mood analysis page
                Navigator.pushNamed(context, '/mood_analysis').then((_) {
                  // Reset flag after visiting mood analysis page
                  setState(() {
                    _hasShownStressPopup = false;
                  });
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.backgroundGradientStart,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View My Progress',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
