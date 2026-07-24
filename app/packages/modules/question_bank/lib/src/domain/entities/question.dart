import 'package:flutter/foundation.dart';

/// Uma questão de múltipla escolha do banco (schema da Spec 01).
@immutable
class Question {
  const Question({
    required this.id,
    required this.source,
    required this.topic,
    required this.level,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.tags = const [],
    this.language = 'pt-BR',
    this.generatedAnswer = false,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] as String,
    source: json['source'] as String,
    topic: json['topic'] as String,
    level: json['level'] as int,
    question: json['question'] as String,
    options: (json['options'] as List).cast<String>(),
    correctIndex: json['correctIndex'] as int,
    explanation: json['explanation'] as String,
    tags: (json['tags'] as List? ?? const []).cast<String>(),
    language: json['language'] as String? ?? 'pt-BR',
    generatedAnswer: json['generated_answer'] as bool? ?? false,
  );

  final String id;
  final String source;
  final String topic;
  final int level;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final List<String> tags;
  final String language;
  final bool generatedAnswer;

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'topic': topic,
    'level': level,
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
    'explanation': explanation,
    'tags': tags,
    'language': language,
    'generated_answer': generatedAnswer,
  };

  @override
  bool operator ==(Object other) => other is Question && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
