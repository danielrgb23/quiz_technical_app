/// Efeitos sonoros curtos do app (assets em `quiz_app/assets/sounds/`,
/// gerados por `scripts/generate_sounds.py`).
enum Sfx { tap, correct, wrong, complete, start, locked }

abstract class SoundService {
  /// Se os sons estão ligados (preferência persistida).
  bool get enabled;

  /// Carrega a preferência salva; seguro chamar mais de uma vez.
  Future<void> load();

  Future<void> setEnabled(bool value);

  /// Toca [sfx] (com haptic leve). Nunca lança: falha de áudio não pode
  /// afetar o fluxo do usuário.
  Future<void> play(Sfx sfx);
}
