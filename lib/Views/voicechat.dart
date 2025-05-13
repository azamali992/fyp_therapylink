import 'package:flutter/material.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/utils/colors.dart';

class VoiceChatPage extends StatefulWidget {
  const VoiceChatPage({super.key});

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage> {
  bool _isRecording = false;
  final bool _isPlaying = false;
  final List<ChatMessage> _messages = [];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar:
          CustomAppBar(screenWidth: screenWidth, screenHeight: screenHeight),
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
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: message.isUser ? AppColors.bgpurple : Colors.grey[800],
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.isUser ? 'You' : 'AI Assistant',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.0,
                ),
              ),
              const SizedBox(height: 4.0),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    message.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    width: 100,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: CustomPaint(
                      painter: WaveformPainter(),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    '0:${message.duration.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleRecording,
                  ),
                  Expanded(
                    child: _isRecording
                        ? CustomPaint(
                            painter: WaveformPainter(isRecording: true),
                            size: const Size(double.infinity, 30),
                          )
                        : const Text(
                            'Tap mic to start recording',
                            style: TextStyle(color: Colors.white70),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            mini: true,
            backgroundColor: AppColors.bgpurple,
            onPressed: _sendMessage,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (!_isRecording) {
        // Add a new message when stopping recording
        _messages.add(ChatMessage(
          isUser: true,
          duration: 15,
          isPlaying: false,
        ));
        // Simulate AI response
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _messages.add(ChatMessage(
              isUser: false,
              duration: 12,
              isPlaying: false,
            ));
          });
        });
      }
    });
  }

  void _sendMessage() {
    if (_isRecording) {
      _toggleRecording();
    }
  }
}

class ChatMessage {
  final bool isUser;
  final int duration;
  bool isPlaying;

  ChatMessage({
    required this.isUser,
    required this.duration,
    required this.isPlaying,
  });
}

class WaveformPainter extends CustomPainter {
  final bool isRecording;

  WaveformPainter({this.isRecording = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    for (var i = 0; i < width; i += 3) {
      final amplitude = isRecording
          ? (DateTime.now().millisecondsSinceEpoch % 1000) / 1000 * 10
          : 5 + (i % 10);
      canvas.drawLine(
        Offset(i.toDouble(), centerY - amplitude),
        Offset(i.toDouble(), centerY + amplitude),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => isRecording;
}
