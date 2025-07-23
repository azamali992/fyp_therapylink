import 'dart:async';
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
  final ValueNotifier<String> _sentimentNotifier =
      ValueNotifier<String>('Unknown');
  String _currentSentiment = 'Unknown';

  bool isRecording = false;
  Timer? _recordingTimer;
  bool _showScrollButton = false;
  bool _isNearBottom = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      // Get ChatBloc from BlocProvider if available, otherwise create a new one
      chatBloc = BlocProvider.of<ChatBloc>(context, listen: false);
      chatBloc.add(ChatLoadMessagesEvent(conversationId: userId));
      _retrieveUsername();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIntroDialog();
      // Add a slight delay to ensure messages are loaded before scrolling
      Future.delayed(const Duration(milliseconds: 500), _scrollToBottom);
    });

    // Add scroll listener to detect when user is near bottom
    _scrollController.addListener(_onScroll);

    chatBloc.stream.listen((state) {
      if (state is ChatSuccessState) {
        // Always scroll to bottom when messages first load
        if (state.messages.isNotEmpty) {
          // Use a small delay to ensure the ListView is built
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        }
      }
    });
  }

  Future<void> _analyzeSentiment(String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    final sentiment = await SentimentRepo.analyzeSentiment(text);
    _currentSentiment = sentiment;
    _sentimentNotifier.value = sentiment;
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

    // Make sure to scroll to bottom to show the loading indicator
    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  // Track scroll position to show/hide scroll button
  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      // Consider "near bottom" if within 150 pixels of the bottom
      final isNearBottom = maxScroll - currentScroll <= 150;

      if (isNearBottom != _isNearBottom) {
        setState(() {
          _isNearBottom = isNearBottom;
          _showScrollButton = !isNearBottom;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      try {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        setState(() {
          _showScrollButton = false;
          _isNearBottom = true;
        });
      } catch (e) {
        // Try again after a short delay if there was an error
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    } else {
      // If controller doesn't have clients yet, retry after a short delay
      Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
    }
  }

  void _toggleVoiceMode() {
    setState(() {
      isRecording = !isRecording;
    });

    if (isRecording) {
      _recordingTimer = Timer(const Duration(seconds: 3), () {
        setState(() => isRecording = false);
        _sendMessage("[Voice message transcribed: I'm feeling anxious today.]");
      });
    } else {
      _recordingTimer?.cancel();
    }
  }

  // Message building is now handled in the ListView builder

  Widget _buildWaveform() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.7),
            Colors.deepPurple.shade300,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Colors.white),
          ),
          const SizedBox(width: 15),
          const Text(
            "Listening...",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          // Animated waveform effect
          SizedBox(
            width: 60,
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (index) => _buildAnimatedBar(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBar(int index) {
    // Create animated bars with different heights and durations
    final heights = [15.0, 25.0, 20.0, 18.0];
    final durations = [900, 700, 800, 600];

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 5, end: heights[index]),
      duration: Duration(milliseconds: durations[index]),
      builder: (context, value, child) {
        return Container(
          width: 4,
          height: value,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      },
      onEnd: () {
        if (mounted && isRecording) {
          setState(() {}); // Trigger rebuild to restart animation
        }
      },
    );
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
    _recordingTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    textEditingController.dispose();
    _scrollController.dispose();
    _sentimentNotifier.dispose();
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
            ValueListenableBuilder<String>(
              valueListenable: _sentimentNotifier,
              builder: (context, sentiment, _) {
                Color bgColor;
                String emoji;
                String displayText;

                final s = sentiment.toLowerCase().trim();
                if (s == 'pos' || s == 'positive') {
                  bgColor = Colors.green;
                  emoji = '😊';
                  displayText = 'Positive';
                } else if (s == 'neg' || s == 'negative') {
                  bgColor = Colors.red;
                  emoji = '😢';
                  displayText = 'Negative';
                } else if (s == 'neu' || s == 'neutral') {
                  bgColor = const Color.fromARGB(255, 58, 9, 172);
                  emoji = '😐';
                  displayText = 'Neutral';
                } else {
                  bgColor = const Color.fromARGB(255, 11, 198, 231);
                  emoji = '🤔';
                  displayText = sentiment;
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: bgColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Sentiment: $displayText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Expanded(
              child: Stack(
                children: [
                  BlocBuilder<ChatBloc, ChatState>(
                    bloc: chatBloc,
                    builder: (context, state) {
                      if (state is ChatSuccessState) {
                        final messages = state.messages;
                        return ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              messages.length + (state.isLoading ? 1 : 0),
                          // This will be called when the ListView is built
                          physics: const AlwaysScrollableScrollPhysics(),
                          // Trigger scroll to bottom when fully built
                          addAutomaticKeepAlives: false,
                          itemBuilder: (context, index) {
                            // Show loading indicator as the last item when waiting for API response
                            if (state.isLoading && index == messages.length) {
                              return _buildLoadingIndicator();
                            }

                            // When the last item is built, scroll to bottom
                            if (index == messages.length - 1) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _scrollToBottom();
                              });
                            }
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isUser)
                                        Container(
                                          width: 18,
                                          height: 18,
                                          margin:
                                              const EdgeInsets.only(right: 6),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Color.fromARGB(
                                                    255, 121, 40, 202),
                                                Color.fromARGB(
                                                    255, 95, 10, 180),
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
                                        MediaQuery.of(context).size.width *
                                            0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(isUser ? 16 : 0),
                                      topRight:
                                          Radius.circular(isUser ? 0 : 16),
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
                                        ? const Color.fromARGB(
                                            255, 106, 27, 154)
                                        : const Color.fromARGB(
                                            255, 74, 20, 140),
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
                  // Floating scroll button that appears when not at bottom
                  if (_showScrollButton)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: AnimatedOpacity(
                        opacity: _showScrollButton ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor:
                                const Color.fromARGB(255, 106, 27, 154)
                                    .withOpacity(0.9),
                            elevation: 4,
                            onPressed: _scrollToBottom,
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isRecording) _buildWaveform(),
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
                        enabled: !isRecording,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 16),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          hintText: isRecording
                              ? "Voice mode enabled..."
                              : "Type your message...",
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
                          prefixIcon: isRecording
                              ? const Icon(Icons.mic_none, color: Colors.red)
                              : null,
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(30),
                    color: isRecording
                        ? Colors.red
                        : const Color.fromARGB(255, 106, 27, 154),
                    child: InkWell(
                      onTap: _toggleVoiceMode,
                      borderRadius: BorderRadius.circular(30),
                      splashColor: Colors.purple[100],
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 22,
                        ),
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
}