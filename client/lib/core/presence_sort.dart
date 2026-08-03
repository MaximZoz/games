import 'package:multigames_client/core/locale_provider.dart';
import 'package:multigames_client/core/presence_repository.dart';
import 'package:multigames_client/utils/relative_time.dart';

/// Онлайн сверху; среди офлайн — кто был в сети недавно выше
/// (дольше всего не был — внизу).
int comparePresenceOnlineFirst(PresenceEntry? a, PresenceEntry? b) {
  final aOnline = a?.online ?? false;
  final bOnline = b?.online ?? false;
  if (aOnline != bOnline) return bOnline ? 1 : -1;
  if (aOnline) return 0;
  final aTime = a?.lastSeenAt;
  final bTime = b?.lastSeenAt;
  if (aTime == null && bTime == null) return 0;
  if (aTime == null) return 1;
  if (bTime == null) return -1;
  final da = DateTime.tryParse(aTime);
  final db = DateTime.tryParse(bTime);
  if (da == null && db == null) return 0;
  if (da == null) return 1;
  if (db == null) return -1;
  return db.compareTo(da);
}

/// «Онлайн» или относительное «был в сети» (например «3 мин назад»).
String formatPresenceStatus(PresenceEntry? presence) {
  if (presence == null) return '';
  if (presence.online) return LocaleService.l10n.commonOnlineCap;
  return formatLastSeen(presence.lastSeenAt);
}

/// Сортирует [items] по presence: онлайн → недавно офлайн → давно офлайн.
void sortByPresenceOnlineFirst<T>(
  List<T> items,
  String Function(T) userIdOf,
  Map<String, PresenceEntry> presence,
) {
  items.sort(
    (a, b) => comparePresenceOnlineFirst(
      presence[userIdOf(a)],
      presence[userIdOf(b)],
    ),
  );
}
