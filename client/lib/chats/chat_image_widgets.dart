import 'dart:typed_data';

import 'package:flutter/material.dart';
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
    this.width = 220,
    this.height = 220,
    this.borderRadius = 14,
  });

  final String messageID;
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ChatMessageImageThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageID != widget.messageID) {
      _load();
    }
  }

  Future<void> _load() async {
    final cached = ref.read(chatImageBytesCacheProvider)[widget.messageID];
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
      final raw = await ref
          .read(chatsRepositoryProvider)
          .fetchMessageImageBytes(widget.messageID);
      final bytes = Uint8List.fromList(raw);
      ref.read(chatImageBytesCacheProvider.notifier).update((m) {
        final next = Map<String, Uint8List>.from(m);
        next[widget.messageID] = bytes;
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
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (_, __, ___) => ChatImageFullscreenViewer(bytes: bytes),
      ),
    );
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

  @override
  State<ChatImageFullscreenViewer> createState() =>
      _ChatImageFullscreenViewerState();
}

class _ChatImageFullscreenViewerState extends State<ChatImageFullscreenViewer> {
  final _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.memory(widget.bytes, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
