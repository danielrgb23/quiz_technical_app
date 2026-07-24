import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/question.dart';
import '../../domain/entities/question_progress.dart';

part 'question_bank_db.g.dart';

@DataClassName('QuestionRow')
class Questions extends Table {
  TextColumn get id => text()();
  TextColumn get source => text()();
  TextColumn get topic => text()();
  IntColumn get level => integer()();
  TextColumn get question => text()();
  TextColumn get optionsJson => text()();
  IntColumn get correctIndex => integer()();
  TextColumn get explanation => text()();
  TextColumn get tagsJson => text()();
  TextColumn get language => text()();
  BoolColumn get generatedAnswer =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProgressRow')
class Progress extends Table {
  TextColumn get questionId => text()();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {questionId};
}

class PendingSync extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class BankMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Questions, Progress, PendingSync, BankMeta])
class QuestionBankDb extends _$QuestionBankDb {
  QuestionBankDb(super.e);

  @override
  int get schemaVersion => 1;

  static const _bankVersionKey = 'bank_version';

  Future<int> bankVersion() async {
    final row = await (select(
      bankMeta,
    )..where((m) => m.key.equals(_bankVersionKey))).getSingleOrNull();
    return row == null ? 0 : int.parse(row.value);
  }

  /// Substitui o banco de questões e grava a versão, atomicamente.
  Future<void> importBank(List<Question> items, int version) {
    return transaction(() async {
      await delete(questions).go();
      await batch((b) {
        b.insertAll(questions, [
          for (final q in items)
            QuestionsCompanion.insert(
              id: q.id,
              source: q.source,
              topic: q.topic,
              level: q.level,
              question: q.question,
              optionsJson: jsonEncode(q.options),
              correctIndex: q.correctIndex,
              explanation: q.explanation,
              tagsJson: jsonEncode(q.tags),
              language: q.language,
              generatedAnswer: Value(q.generatedAnswer),
            ),
        ]);
      });
      await into(bankMeta).insertOnConflictUpdate(
        BankMetaCompanion.insert(key: _bankVersionKey, value: '$version'),
      );
    });
  }
}

Question questionFromRow(QuestionRow row) => Question(
  id: row.id,
  source: row.source,
  topic: row.topic,
  level: row.level,
  question: row.question,
  options: (jsonDecode(row.optionsJson) as List).cast<String>(),
  correctIndex: row.correctIndex,
  explanation: row.explanation,
  tags: (jsonDecode(row.tagsJson) as List).cast<String>(),
  language: row.language,
  generatedAnswer: row.generatedAnswer,
);

QuestionProgress progressFromRow(ProgressRow row) => QuestionProgress(
  questionId: row.questionId,
  correctCount: row.correctCount,
  wrongCount: row.wrongCount,
  lastSeenAt: row.lastSeenAt,
  nextReviewAt: row.nextReviewAt,
);
