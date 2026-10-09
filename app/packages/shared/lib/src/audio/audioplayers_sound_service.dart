import 'package:audioplayers/audioplayers.dart';
import 'package:core/core.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import 'sound_service.dart';

@LazySingleton(as: SoundService)
class AudioplayersSoundService implements SoundService {
  AudioplayersSoundService(this._storage);

  final LocalStorage _storage;

  static const _enabledKey = 'sound_enabled';

  final Map<Sfx, AudioPlayer> _players = {};
  bool _enabled = true;
  bool _loaded = false;

  @override
  bool get enabled => _enabled;

  @override
  Future<void> load() async {
    if (_loaded) return;
    _enabled = await _storage.getBool(_enabledKey) ?? true;
    _loaded = true;
  }

  @override
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    _loaded = true;
    await _storage.setBool(_enabledKey, value: value);
  }

  @override
  Future<void> play(Sfx sfx) async {
    try {
      await load();
      if (!_enabled) return;
      _haptic(sfx);
      final player = _players.putIfAbsent(sfx, () {
        final p = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
        return p;
      });
      await player.stop();
      await player.play(AssetSource('sounds/${sfx.name}.wav'), volume: 0.8);
    } catch (e) {
      AppLogger.warning('Falha ao tocar ${sfx.name}', tag: 'Sound', error: e);
    }
  }

  void _haptic(Sfx sfx) {
    switch (sfx) {
      case Sfx.correct || Sfx.complete:
        HapticFeedback.mediumImpact();
      case Sfx.wrong || Sfx.locked:
        HapticFeedback.heavyImpact();
      case Sfx.tap || Sfx.start:
        HapticFeedback.selectionClick();
    }
  }
}
