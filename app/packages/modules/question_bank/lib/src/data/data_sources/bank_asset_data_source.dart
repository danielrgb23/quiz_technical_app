import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/bank_manifest.dart';
import '../../domain/entities/question.dart';

/// Carrega o banco embarcado (output da Spec 01) dos assets do app.
class BankAssetDataSource {
  BankAssetDataSource({
    this.questionsAssetPath = 'assets/question_bank/questions.json',
    this.manifestAssetPath = 'assets/question_bank/manifest.json',
    Future<String> Function(String path)? loadString,
  }) : _loadString = loadString ?? rootBundle.loadString;

  final String questionsAssetPath;
  final String manifestAssetPath;
  final Future<String> Function(String path) _loadString;

  Future<BankManifest> loadManifest() async {
    final raw = await _loadString(manifestAssetPath);
    return BankManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<List<Question>> loadQuestions() async {
    final raw = await _loadString(questionsAssetPath);
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list) Question.fromJson(item as Map<String, dynamic>),
    ];
  }
}
