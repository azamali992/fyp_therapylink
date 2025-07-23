import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:therapylink/bloc/chat_bloc.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/repos/sentiment_repo.dart';

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
  String _currentSentiment = 'Unknown';

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
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIntroDialog();
    });
  }

  Future<void> _analyzeSentiment(String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    final sentiment = await SentimentRepo.analyzeSentiment(text);
    setState(() {
      _currentSentiment = sentiment;
    });
  }

  void _showIntroDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.backgroundGradientStart,
          title: const Text(
            "TherapyLink: Meet Your AI Psychologist",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: const Text(
            "Hello! I'm your AI Psychologist, here to listen, support, and guide you. Feel free to share your thoughts, and I'll do my best to help you on your journey.",
            style: TextStyle(color: Color.fromARGB(214, 235, 220, 16)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text("Got it", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _retrieveUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString("loggedInUserEmail");

    if (email != null) {
      String? storedUsername = await getUserName(email);
      if (storedUsername != null) {
        setState(() {
          _username = storedUsername;
        });
      }
    }
  }

  Future<String?> getUserName(String email) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUsers = prefs.getString("users");

    if (storedUsers != null) {
      Map<String, dynamic> users = json.decode(storedUsers);
      return users[email];
    }
    return null;
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
      appBar:
          CustomAppBar(screenWidth: screenWidth, screenHeight: screenHeight),
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

                        return Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
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
    if (s == 'pos' || s == 'positive') {
      return Colors.green;
    } else if (s == 'neg' || s == 'negative') {
      return Colors.red;
    } else if (s == 'neu' || s == 'neutral') {
      return const Color.fromARGB(255, 58, 9, 172);
    }
    return const Color.fromARGB(255, 11, 198, 231);
  }

  String _getSentimentEmoji() {
    final s = _currentSentiment.toLowerCase().trim();
    if (s == 'pos' || s == 'positive') {
      return '😊';
    } else if (s == 'neg' || s == 'negative') {
      return '😢';
    } else if (s == 'neu' || s == 'neutral') {
      return '😐';
    }
    return '🤔';
  }

  String _getSentimentText() {
    final s = _currentSentiment.toLowerCase().trim();
    if (s == 'pos' || s == 'positive') {
      return 'Positive';
    } else if (s == 'neg' || s == 'negative') {
      return 'Negative';
    } else if (s == 'neu' || s == 'neutral') {
      return 'Neutral';
    }
    return _currentSentiment;
  }
}
