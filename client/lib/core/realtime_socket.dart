abstract class RealtimeSocket {
  Stream<String> get messages;

  /// Срабатывает, когда сокет реально открыт (на IO — после async connect).
  Stream<void> get connected;

  bool get isOpen;
  void close();
}
