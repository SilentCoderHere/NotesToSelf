// Updated: models/note.dart
import 'dart:convert';

class Note {
  final int? id;
  final String text;
  final DateTime createdAt;
  final int? replyToId; // NEW: tracks the note being replied to

  Note({this.id, required this.text, required this.createdAt, this.replyToId});

  Note copyWith({int? id, String? text, DateTime? createdAt, int? replyToId}) {
    return Note(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      replyToId: replyToId ?? this.replyToId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'reply_to_id': replyToId, // store in DB
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as int?;
    final text = map['text'] as String?;
    final createdAtString = map['created_at'] as String?;
    final replyToId = map['reply_to_id'] as int?;

    if (text == null || createdAtString == null) {
      throw Exception('Missing required field in map');
    }

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(createdAtString);
    } catch (e) {
      throw Exception('Invalid date format for createdAt');
    }

    return Note(id: id, text: text, createdAt: createdAt, replyToId: replyToId);
  }

  String toJson() => jsonEncode(toMap());

  factory Note.fromJson(String source) => Note.fromMap(jsonDecode(source));
}
