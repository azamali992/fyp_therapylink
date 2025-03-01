import 'dart:math';

import 'package:therapylink/models/chat_message_model.dart';
import 'package:therapylink/utils/const.dart';
import 'package:dio/dio.dart';

class ChatRepo {
  static Future<String> chatTextGenerationRepo(
      List<ChatMessageModel> previousMessages) async {
    try {
      Dio dio = Dio();

      // ignore: unused_local_variable
      final response = await dio.post(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apikey",
          data: {
            "contents": previousMessages.map((e) => e.toMap()).toList(),
            "systemInstruction": {
              "role": "user",
              "parts": [
                {
                  "text":
                      "it should give answers as a psychologist\nand keep answer like human and short,remember you are a professional therapist with a PhD in it . you have completed your supervised clinical hours and have passed your licensing exam. your name is dr fizza.if the user talks in roman urdu then you should respond in roman urdu\nact like a mature psychologist and do not be emotional\n"
                }
              ]
            },
            "generationConfig": {
              "temperature": 1,
              "topK": 40,
              "topP": 0.95,
              "maxOutputTokens": 8192,
              "responseMimeType": "text/plain"
            }
          });
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response
            .data['candidates'].first['content']['parts'].first['text'];
      } else {
        return "Error";
      }
    } catch (e) {
      log(e.toString() as num);
      return "Error";
    }
  }
}
