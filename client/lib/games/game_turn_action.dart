import 'package:multigames_client/games/games_repository.dart';

/// Синхронный замок хода: второй тап в том же кадре не уходит на сервер.
///
/// `setState(_busy = true)` глушит кнопку только после пересборки. Два клика
/// по «Фолд»/«Чек» оба проходят `if (_busy)` и второй отвечает «не ваш ход».
class GameTurnActionLock {
  bool _held = false;

  bool get held => _held;

  bool tryAcquire() {
    if (_held) return false;
    _held = true;
    return true;
  }

  void release() {
    _held = false;
  }
}

/// Повторный ход после смены очереди — не показывать «Сейчас не ваш ход».
bool isStaleNotYourTurnError(Object error) {
  if (error is GamesException) {
    final blob = '${error.errorKey}\n${error.message}'.toLowerCase();
    if (_looksLikeNotYourTurn(blob)) return true;
  }
  return _looksLikeNotYourTurn(error.toString().toLowerCase());
}

bool _looksLikeNotYourTurn(String blob) =>
    blob.contains('not your turn') || blob.contains('не ваш ход');
