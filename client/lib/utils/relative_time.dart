const List<String> _weekdayShort = ['вс', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб'];
const List<String> _monthShort = [
  'янв', 'фев', 'мар', 'апр', 'май', 'июн',
  'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
];

/// Компактный формат даты/времени для списка чатов: сегодня — только время,
/// вчера — «вчера», на неделе — день, иначе краткая дата.
String formatChatListDateTime(String? raw) {
  final dt = DateTime.tryParse(raw ?? '');
  if (dt == null) return '';
  final local = dt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDay = DateTime(local.year, local.month, local.day);

  if (msgDay == today) {
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  final yesterday = today.subtract(const Duration(days: 1));
  if (msgDay == yesterday) {
    return 'вчера';
  }
  final diffDays = today.difference(msgDay).inDays;
  if (diffDays < 7) {
    return _weekdayShort[local.weekday % 7];
  }
  if (local.year == now.year) {
    return '${local.day} ${_monthShort[local.month - 1]}';
  }
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year % 100}';
}

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
