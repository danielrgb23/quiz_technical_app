import 'sound_service.dart';

/// Sem som; usado em testes.
class FakeSoundService implements SoundService {
  final List<Sfx> played = [];
  bool _enabled = true;

  @override
  bool get enabled => _enabled;

  @override
  Future<void> load() async {}

  @override
  Future<void> setEnabled(bool value) async => _enabled = value;

  @override
  Future<void> play(Sfx sfx) async {
    if (_enabled) played.add(sfx);
  }
}
