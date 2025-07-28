import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_speech/google_speech.dart';
import 'package:lottie/lottie.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:therapylink/bloc/chat_bloc.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class VoiceChatPage extends StatefulWidget {
  const VoiceChatPage({super.key});

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage>
    with SingleTickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  final String conversationId = "default_conversation";

  late AnimationController _lottieController;
  late RiveAnimationController _riveController;

  bool _isListening = false;
  String _aiResponse = "";
  late SpeechToText _googleSpeech;

  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _riveController = SimpleAnimation('idle');

    _aiResponse =
        "Hello! How can I help you Today ?"; // ✅ Custom opening message

    _initTTS();
    _initGoogleSpeech();
    requestMicPermission();

    // ✅ Load previous messages so chatbot works
    context
        .read<ChatBloc>()
        .add(ChatLoadMessagesEvent(conversationId: conversationId));
  }

  Future<void> requestMicPermission() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        await openAppSettings();
      }
    }
  }

  void _initTTS() {
    _flutterTts.setPitch(1.0);
    _flutterTts.setSpeechRate(0.6);
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _riveController = SimpleAnimation('idle');
      });
    });
  }

  Future<void> _initGoogleSpeech() async {
    final serviceAccount = ServiceAccount.fromString(
      await rootBundle.loadString('assets/google_speech.json'),
    );
    _googleSpeech = SpeechToText.viaServiceAccount(serviceAccount);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopAndTranscribe();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        await requestMicPermission();
        return;
      }

      setState(() {
        _isListening = true;
        _aiResponse = "Listening...";
        _riveController = SimpleAnimation('blink');
      });

      _lottieController.reset();
      if (_lottieController.duration != null) {
        _lottieController.repeat(period: _lottieController.duration);
      }

      final tempPath = "${Directory.systemTemp.path}/speech_recording.wav";

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: tempPath,
      );

      print("🎤 Recording started: $tempPath");
    } catch (e) {
      print("❌ Error starting recording: $e");
    }
  }

  Future<void> _stopAndTranscribe() async {
    try {
      final path = await _recorder.stop();
      setState(() {
        _isListening = false;
        _aiResponse = "Thinking...";
        _riveController = SimpleAnimation('idle');
      });
      _lottieController.reset();

      if (path == null) {
        setState(() {
          _aiResponse = "No audio captured.";
        });
        return;
      }

      print("✅ Recording stopped, file saved: $path");
      await _transcribeAudio(path);
    } catch (e) {
      print("❌ Error stopping recording: $e");
      setState(() {
        _aiResponse = "Recording failed.";
      });
    }
  }

  Future<void> _transcribeAudio(String path) async {
    try {
      final audioBytes = await File(path).readAsBytes();
      final response = await _googleSpeech.recognize(
        RecognitionConfig(
          encoding: AudioEncoding.LINEAR16,
          languageCode: 'en-US',
          sampleRateHertz: 16000,
          enableAutomaticPunctuation: true,
          model: RecognitionModel.command_and_search,
        ),
        audioBytes,
      );

      if (response.results.isNotEmpty &&
          response.results.first.alternatives.isNotEmpty) {
        final text = response.results
            .map((e) => e.alternatives.first.transcript)
            .join(" ");

        print("✅ Transcribed: $text");

        setState(() {
          _aiResponse = text;
        });

        context.read<ChatBloc>().add(ChatGenerateNewTextMessageEvent(
              inputMessage: text.trim(),
              conversationId: conversationId,
            ));
      } else {
        print("❌ No speech detected");
        setState(() {
          _aiResponse = "Didn't catch that, try again.";
        });
      }
    } catch (e) {
      print("❌ Transcription error: $e");
      setState(() {
        _aiResponse = "Error processing speech.";
      });
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    setState(() {
      _riveController = SimpleAnimation('talk');
    });
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Therapist',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Voice Chat Session',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? Colors.red.withOpacity(0.15)
                            : Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isListening
                              ? Colors.red.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isListening ? Colors.red : Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isListening ? 'Recording' : 'Ready',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (context, state) {
                    if (state is ChatSuccessState &&
                        state.messages.isNotEmpty) {
                      final lastMessage = state.messages.last;

                      if (lastMessage.role == "model") {
                        if (_isFirstLoad) {
                          _isFirstLoad = false;
                          return;
                        }

                        setState(() {
                          _aiResponse = lastMessage.parts.first.text;
                        });

                        _speak(lastMessage.parts.first.text);
                      }
                    }
                  },
                  builder: (context, state) {
                    String displayText = _isListening
                        ? "I'm listening... speak naturally"
                        : (state is ChatLoadingState
                            ? "Processing your message..."
                            : (_aiResponse.isNotEmpty
                                ? _aiResponse
                                : "Tap the microphone to start our conversation"));

                    return Column(
                      children: [
                        // Avatar/Animation Section
                        Expanded(
                          flex: 3,
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: RiveAnimation.asset(
                                'assets/chatbot.riv',
                                controllers: [_riveController],
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                        ),

                        // Response Text Section
                        Expanded(
                          flex: 2,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.12),
                                  Colors.white.withOpacity(0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  if (state is ChatLoadingState) ...[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Thinking...',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Text(
                                    displayText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      height: 1.6,
                                      letterSpacing: 0.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Voice Controls Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Microphone Button
                              GestureDetector(
                                onTap: _toggleListening,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _isListening
                                          ? [
                                              Colors.red.shade400,
                                              Colors.red.shade600,
                                            ]
                                          : [
                                              Colors.blue.shade400,
                                              Colors.purple.shade600,
                                            ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isListening
                                                ? Colors.red
                                                : Colors.blue)
                                            .withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (_isListening)
                                        Lottie.asset(
                                          'assets/mic_listening.json',
                                          controller: _lottieController,
                                          width: 100,
                                          height: 100,
                                          onLoaded: (composition) {
                                            _lottieController.duration =
                                                composition.duration;
                                            if (_isListening) {
                                              _lottieController.repeat(
                                                  period: composition.duration);
                                            }
                                          },
                                        ),
                                      if (!_isListening)
                                        const Icon(
                                          Icons.mic_rounded,
                                          size: 48,
                                          color: Colors.white,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isListening
                                    ? 'Tap to stop recording'
                                    : 'Tap to start speaking',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
