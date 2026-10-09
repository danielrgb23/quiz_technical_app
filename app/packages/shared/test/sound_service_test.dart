import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  test('FakeSoundService registra sons e respeita o mudo', () async {
    final sound = FakeSoundService();
    await sound.play(Sfx.correct);
    await sound.setEnabled(false);
    await sound.play(Sfx.wrong);
    expect(sound.played, [Sfx.correct]);
    expect(sound.enabled, isFalse);
  });
}
