import 'package:flutter/foundation.dart';

/// Manifest de uma versão do banco de questões (Spec 01).
@immutable
class BankManifest {
  const BankManifest({
    required this.version,
    required this.count,
    required this.checksum,
    this.generatedAt,
  });

  factory BankManifest.fromJson(Map<String, dynamic> json) => BankManifest(
    version: json['version'] as int,
    count: json['count'] as int,
    checksum: json['checksum'] as String,
    generatedAt: json['generatedAt'] as String?,
  );

  final int version;
  final int count;

  /// SHA-256 do arquivo `questions_v<N>.json` (hex).
  final String checksum;
  final String? generatedAt;
}
