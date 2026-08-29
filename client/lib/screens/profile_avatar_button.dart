/// Подпись кнопки круглого аватара: всегда «Поменять аватар».
/// «Загрузить фото» не используем — рядом уже галерея из трёх слотов.
String profileAvatarActionLabel({
  required bool processing,
  required String processingLabel,
  required String changeLabel,
}) {
  return processing ? processingLabel : changeLabel;
}
