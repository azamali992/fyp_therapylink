import 'dart:convert';

class ChatMessageModel {
  final String role;
  final List<ChatPartModel> parts;
  final int timestamp;

  ChatMessageModel({
    required this.role,
    required this.parts,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'parts': parts.map((x) => x.toMap()).toList(),
      'timestamp': timestamp,
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      role: map['role'] as String,
      parts: (map['parts'] as List<dynamic>)
          .map((x) => ChatPartModel.fromMap(x as Map<String, dynamic>))
          .toList(),
      timestamp: map['timestamp'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatMessageModel.fromJson(String source) =>
      ChatMessageModel.fromMap(json.decode(source));
}

class ChatPartModel {
  final String text;

  ChatPartModel({required this.text});

  Map<String, dynamic> toMap() {
    return {'text': text};
  }

  factory ChatPartModel.fromMap(Map<String, dynamic> map) {
    return ChatPartModel(text: map['text'] as String);
  }

  String toJson() => json.encode(toMap());

  factory ChatPartModel.fromJson(String source) =>
      ChatPartModel.fromMap(json.decode(source));
}
