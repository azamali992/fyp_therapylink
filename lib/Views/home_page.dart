import 'dart:convert';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/bloc/chat_bloc.dart';
import 'package:therapylink/models/chat_message_model.dart';
import 'package:therapylink/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import the intl package

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final ChatBloc chatBloc = ChatBloc();
  TextEditingController textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _username = "User";

  @override
  void initState() {
    super.initState();
    _retrieveUsername();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIntroDialog();
    });
    chatBloc.stream.listen((state) {
      if (state is ChatSuccessState) {
        _scrollToBottom();
      }
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
              color: AppColors.textWhite,
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar:
            CustomAppBar(screenWidth: screenWidth, screenHeight: screenHeight),
        // backgroundColor: const Color.fromARGB(255, 52, 6, 63),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.backgroundGradientStart,
                AppColors.backgroundGradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: BlocConsumer<ChatBloc, ChatState>(
            bloc: chatBloc,
            listener: (context, state) {},
            builder: (context, state) {
              if (state is ChatSuccessState) {
                List<ChatMessageModel> messages = state.messages;

                return SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(
                                AppConstants.largeBorderRadius),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              bool isUserMessage =
                                  messages[index].role == "user";
                              String timestamp = DateFormat('hh:mm a')
                                  .format(DateTime.now()); // Get current time

                              return Column(
                                crossAxisAlignment: isUserMessage
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      isUserMessage
                                          ? _username
                                          : "Psychologist",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: isUserMessage
                                          ? const Color.fromARGB(
                                              255, 101, 10, 187)
                                          : const Color.fromARGB(
                                              255, 55, 4, 88),
                                    ),
                                    child: Text(
                                      messages[index].parts.first.text,
                                      style: TextStyle(
                                        color: isUserMessage
                                            ? const Color.fromARGB(
                                                255, 254, 255, 255)
                                            : const Color.fromARGB(
                                                255, 243, 243, 243),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      timestamp, // Display live timestamp
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: textEditingController,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () {
                                if (textEditingController.text.isNotEmpty) {
                                  String text = textEditingController.text;
                                  textEditingController.clear();
                                  chatBloc.add(ChatGenerateNewTextMessageEvent(
                                      inputMessage: text));
                                }
                              },
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Theme.of(context).primaryColor,
                                child:
                                    const Icon(Icons.send, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}
