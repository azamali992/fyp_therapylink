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

    _aiResponse = "Hello! How can I help you Today ?"; // ✅ Custom opening message

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
      appBar: AppBar(
        title: const Text("Psychologist", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.backgroundGradientStart,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatSuccessState && state.messages.isNotEmpty) {
              final lastMessage = state.messages.last;

              if (lastMessage.role == "model") {
                if (_isFirstLoad) {
                  // ✅ Do NOT override your custom text on first load
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
                ? "Listening..."
                : (state is ChatLoadingState
                    ? "Thinking..."
                    : (_aiResponse.isNotEmpty
                        ? _aiResponse
                        : "Tap the mic to talk"));

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: RiveAnimation.asset(
                      'assets/chatbot.riv',
                      controllers: [_riveController],
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 36.0),
                  child: GestureDetector(
                    onTap: _toggleListening,
                    child: Lottie.asset(
                      'assets/mic_listening.json',
                      controller: _lottieController,
                      width: 300,
                      height: 300,
                      onLoaded: (composition) {
                        _lottieController.duration = composition.duration;
                        if (_isListening) {
                          _lottieController
                              .repeat(period: composition.duration);
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
