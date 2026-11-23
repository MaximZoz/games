import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show formatTurnTime, rulesStakeLine;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Число строк шапки шаблона: ставка, игроки, режим, время на ход.
const int kGameRulesHeaderLines = 4;

/// Единый шаблон правил любой игры — карточка, лобби, приглашение, партия.
///
/// Порядок жёсткий и одинаковый везде: ставка → игроки → режим → время на
/// ход → правила. Первые четыре строки есть всегда: без ставки пишем «Без
/// ставки», без лимита — «Без ограничения по времени». Всё остальное
/// (колода, контроль партии, время расстановки, заметка про офлайн) игра
/// кладёт в [rules].
///
/// Новая игра собирает правила только через эту функцию, а не списком строк
/// руками — иначе порядок снова разъедется.
List<String> gameRuleLines({
  required int stakeBronze,
  required int players,
  required String mode,
  required int turnTimeSec,
  required List<String> rules,
  AppLocalizations? l10n,
}) {
  final t = l10n ?? LocaleService.l10n;
  return [
    stakeBronze > 0 ? rulesStakeLine(stakeBronze, t) : t.rulesStakeNone,
    t.rulesPlayers(players),
    t.rulesMode(mode),
    turnTimeSec > 0
        ? t.rulesTurnTime(formatTurnTime(turnTimeSec))
        : t.rulesNoTimeLimit,
    ...rules,
  ];
}
