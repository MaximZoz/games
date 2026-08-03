import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime;

/// Подпись режима игры «Дурак».
String durakModeLabel(String mode) =>
    mode == 'perevodnoi' ? 'Переводной' : 'Подкидной';

/// Подпись размера колоды.
String durakDeckLabel(int n) {
  switch (n) {
    case 24:
      return '24 карты';
    case 52:
      return '52 карты';
    default:
      return '36 карт';
  }
}

/// Строки правил «Дурака» — единый источник для карточки игры, приглашения
/// и экрана лобби. [offlineBot] убирает ставку и время на ход.
List<String> durakRuleLines({
  required String mode,
  required int players,
  required int deckSize,
  required int turnTimeSec,
  required int stakeBronze,
  bool offlineBot = false,
}) {
  return [
    'Режим: ${durakModeLabel(mode)}',
    'Игроки: $players. Колода: ${durakDeckLabel(deckSize)}.',
    if (offlineBot)
      'Игра против бота, без ставок и лимита времени.'
    else ...[
      turnTimeSec == 0
          ? 'Без ограничения по времени на ход.'
          : 'Время на ход: ${formatTurnTime(turnTimeSec)}.',
      if (stakeBronze > 0)
        'Ставка: $stakeBronze. На столько монет идёт игра.',
    ],
    'Атакующий кладёт карты, защитник бьёт (той же масти старше или козырем). '
        'Козырь бьётся только козырем старше.',
    'Когда все карты биты — атакующий говорит «Бито», карты уходят в отбой. '
        'Иначе защитник берёт всё со стола.',
    'Проигравший — у кого в конце партии остались карты, «дурак».',
  ];
}
