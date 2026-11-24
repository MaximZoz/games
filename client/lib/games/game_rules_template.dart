import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/games/games_repository.dart'
    show rulesStakeLine;
import 'package:multigames_client/l10n/app_localizations.dart';

/// Число строк шапки шаблона: ставка, игроки, режим.
const int kGameRulesHeaderLines = 3;

/// Единый шаблон правил любой игры — карточка, лобби, приглашение, партия.
///
/// Порядок жёсткий и одинаковый везде: ставка → игроки → режим → правила.
/// Первые три строки есть всегда: без ставки пишем «Без ставки». Строка
/// ставки заканчивается точкой. Время на ход в правилах не пишем — его
/// видно на таймере партии. [turnTimeSec] остаётся в сигнатуре, чтобы
/// игры по-прежнему передавали лимит, но в текст он не попадает.
/// Всё остальное (колода, контроль партии, время расстановки, заметка
/// про офлайн) игра кладёт в [rules].
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
    ...rules,
  ];
}
