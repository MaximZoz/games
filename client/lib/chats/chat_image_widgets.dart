import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigames_client/chats/chats_provider.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Кэш байтов фото сообщений в рамках сессии.
final chatImageBytesCacheProvider =
    StateProvider<Map<String, Uint8List>>((ref) => {});

class ChatMessageImageThumb extends ConsumerStatefulWidget {
  const ChatMessageImageThumb({
    super.key,
    required this.messageID,
    this.imageIndex = 0,
    this.width = 220,
    this.height = 220,
    this.borderRadius = 14,
  });

  final String messageID;
  final int imageIndex;
  final double width;
  final double height;
  final double borderRadius;

  @override
  ConsumerState<ChatMessageImageThumb> createState() =>
      _ChatMessageImageThumbState();
}

class _ChatMessageImageThumbState extends ConsumerState<ChatMessageImageThumb> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _failed = false;

  String get _cacheKey => '${widget.messageID}#${widget.imageIndex}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ChatMessageImageThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageID != widget.messageID ||
        oldWidget.imageIndex != widget.imageIndex) {
      _load();
    }
  }

  Future<void> _load() async {
    final cached = ref.read(chatImageBytesCacheProvider)[_cacheKey];
    if (cached != null) {
      setState(() {
        _bytes = cached;
        _loading = false;
        _failed = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final raw = await ref.read(chatsRepositoryProvider).fetchMessageImageBytes(
            widget.messageID,
            index: widget.imageIndex,
          );
      final bytes = Uint8List.fromList(raw);
      ref.read(chatImageBytesCacheProvider.notifier).update((m) {
        final next = Map<String, Uint8List>.from(m);
        next[_cacheKey] = bytes;
        return next;
      });
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _openViewer() {
    final bytes = _bytes;
    if (bytes == null) return;
    ChatImageFullscreenViewer.open(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _bytes == null ? null : _openViewer,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          width: widget.width,
          height: widget.height,
          color: AppColors.accentSoft,
          child: _loading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _failed || _bytes == null
                  ? const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Image.memory(
                      _bytes!,
                      fit: BoxFit.cover,
                      width: widget.width,
                      height: widget.height,
                    ),
        ),
      ),
    );
  }
}

class ChatImageFullscreenViewer extends StatefulWidget {
  const ChatImageFullscreenViewer({super.key, required this.bytes});

  final Uint8List bytes;

  /// Поверх всего приложения (без тулбара shell), на весь экран.
  static Future<void> open(BuildContext context, Uint8List bytes) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        fullscreenDialog: true,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ChatImageFullscreenViewer(bytes: bytes),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<ChatImageFullscreenViewer> createState() =>
      _ChatImageFullscreenViewerState();
}

class _ChatImageFullscreenViewerState extends State<ChatImageFullscreenViewer> {
  final _controller = TransformationController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _close,
                  child: InteractiveViewer(
                    transformationController: _controller,
                    minScale: 1,
                    maxScale: 5,
                    child: Center(
                      child: Image.memory(
                        widget.bytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.viewPaddingOf(context).top + 4,
                right: 8,
                child: IconButton(
                  onPressed: _close,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
