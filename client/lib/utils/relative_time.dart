/// Форматирует "последний раз в сети" для отображения пользователю.
String formatLastSeen(String? lastSeenAt) {
  if (lastSeenAt == null || lastSeenAt.isEmpty) return '';
  final dt = DateTime.tryParse(lastSeenAt);
  if (dt == null) return '';
  return formatLastSeenFromDateTime(dt);
}

/// Форматирует дату относительно текущего времени.
String formatLastSeenFromDateTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt.toLocal());

  if (diff.inSeconds < 60) {
    return 'только что';
  }
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    if (m == 1) return '1 мин назад';
    if (m < 5) return '$m мин назад';
    if (m < 21) return '$m мин назад';
    return '$m мин назад';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    if (h == 1) return '1 ч назад';
    if (h < 5) return '$h ч назад';
    if (h < 21) return '$h ч назад';
    return '$h ч назад';
  }
  if (diff.inDays == 1) {
    return 'вчера';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} дн. назад';
  }
  if (diff.inDays < 30) {
    final w = (diff.inDays / 7).floor();
    if (w == 1) return 'неделю назад';
    if (w < 5) return '$w нед. назад';
    return 'месяц назад';
  }
  if (diff.inDays < 365) {
    final m = (diff.inDays / 30).floor();
    if (m == 1) return 'месяц назад';
    if (m < 5) return '$m мес. назад';
    if (m < 12) return '$m мес. назад';
    return 'год назад';
  }
  final y = (diff.inDays / 365).floor();
  if (y == 1) return 'год назад';
  return '$y г. назад';
}
