abstract class RealtimeSocket {
  Stream<String> get messages;
  bool get isOpen;
  void close();
}
