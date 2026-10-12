import 'package:multigames_client/games/framework/game_registry.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/l10n/app_localizations.dart';
import 'package:multigames_client/l10n/display_names.dart';

/// Последние партии выбранного среза: все игры, одна игра или игра и режим.
List<RecentGame> statsRecentSlice(
  List<RecentGame> recent, {
  required String game,
  required String mode,
  int limit = 10,
}) {
  if (limit <= 0) return const [];
  final out = <RecentGame>[];
  for (final item in recent) {
    if (game.isNotEmpty && item.gameType != game) continue;
    if (mode.isNotEmpty && item.mode != mode) continue;
    out.add(item);
    if (out.length >= limit) break;
  }
  return out;
}

/// Режимы, которые можно выбрать в статистике.
///
/// Короткий фиксированный список плюс режимы, которые уже есть в истории,
/// если сервер прислал незнакомый ключ.
List<String> statsModeOptions(String gameType, Iterable<String> played) {
  const canonical = <String, List<String>>{
    'tictactoe': ['classic', 'gomoku', 'ultimate', 'multi3', 'multi4'],
    'durak': ['2:24', '2:36', '3:36', '3:52', '4:36', '4:52'],
    'checkers': ['russian', 'english', 'giveaway', 'corners'],
    'nardy': ['short', 'long'],
    'chess': ['classic', 'rapid', 'blitz', 'bullet'],
  };
  final out = List<String>.from(canonical[gameType] ?? const <String>[]);
  for (final mode in played) {
    final value = mode.trim();
    if (value.isEmpty || out.contains(value)) continue;
    out.add(value);
  }
  return out;
}

/// Подпись чипа режима.
String statsModeLabel(String gameType, String mode, AppLocalizations l10n) {
  if (gameType == 'durak') {
    final parts = mode.split(':');
    if (parts.length == 2) {
      final players = int.tryParse(parts[0]) ?? 2;
      final deck = parts[1];
      return l10n.statsDurakChip(players, deck);
    }
  }
  final label = localizedGameModeLabel(
    gameType: gameType,
    variant: mode,
    gameMode: mode,
    l10n: l10n,
  );
  return label.isEmpty ? mode : label;
}

/// Типы игр для переключателя: сыгранные, в порядке карточек хаба.
List<String> statsGameTypes(Iterable<String> ids) {
  final unique = <String>{};
  for (final id in ids) {
    final value = id.trim();
    if (value.isNotEmpty) unique.add(value);
  }
  final list = unique.toList();
  list.sort((a, b) {
    final ao = gameRegistry[a]?.sortOrder ?? 1000;
    final bo = gameRegistry[b]?.sortOrder ?? 1000;
    return ao.compareTo(bo);
  });
  return list;
}
