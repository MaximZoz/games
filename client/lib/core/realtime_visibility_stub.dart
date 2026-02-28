/// Заглушка для не-Web платформ: отключение по скрытию вкладки не требуется.
void Function()? setupRealtimeVisibilityDisconnect({
  required Duration hiddenTimeout,
  required void Function() onHiddenTimeout,
  required void Function() onVisible,
}) =>
    null;
