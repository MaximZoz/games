import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';

const int avatarMaxSidePx = 96;
const int avatarStorageLimitBytes = 45 * 1024;

Future<Uint8List?> compactAvatarBytes(Uint8List source) async {
  ui.Codec? probeCodec;
  ui.Image? probeImage;
  try {
    probeCodec = await ui.instantiateImageCodec(source);
    final probeFrame = await probeCodec.getNextFrame();
    probeImage = probeFrame.image;

    final width = probeImage.width;
    final height = probeImage.height;
    final longestSide = math.max(width, height);
    final scale =
        longestSide > avatarMaxSidePx ? avatarMaxSidePx / longestSide : 1.0;

    final targetWidth = math.max(1, (width * scale).round());
    final targetHeight = math.max(1, (height * scale).round());

    final codec = await ui.instantiateImageCodec(
      source,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    codec.dispose();

    if (bytes == null) return null;
    return bytes.buffer.asUint8List();
  } catch (_) {
    return null;
  } finally {
    probeImage?.dispose();
    probeCodec?.dispose();
  }
}

Future<String?> buildCompactAvatarValue(Uint8List source) async {
  final compact = await compactAvatarBytes(source);
  final bytes = compact ?? source;
  if (bytes.lengthInBytes > avatarStorageLimitBytes) {
    return null;
  }
  return 'base64,${base64Encode(bytes)}';
}

Future<Uint8List?> showAvatarCropDialog({
  required BuildContext context,
  required Uint8List sourceBytes,
}) {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => AvatarCropDialog(sourceBytes: sourceBytes),
  );
}

class AvatarCropDialog extends StatefulWidget {
  const AvatarCropDialog({super.key, required this.sourceBytes});

  final Uint8List sourceBytes;

  @override
  State<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<AvatarCropDialog> {
  static const double _viewportSize = 240;

  final TransformationController _transformation = TransformationController();
  final GlobalKey _captureKey = GlobalKey();

  bool _ready = false;
  bool _exporting = false;
  double _baseWidth = _viewportSize;
  double _baseHeight = _viewportSize;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(widget.sourceBytes);
      final frame = await codec.getNextFrame();
      image = frame.image;

      final width = image.width.toDouble();
      final height = image.height.toDouble();
      final aspect = (height == 0) ? 1.0 : width / height;

      double baseWidth;
      double baseHeight;
      if (aspect >= 1) {
        baseHeight = _viewportSize;
        baseWidth = _viewportSize * aspect;
      } else {
        baseWidth = _viewportSize;
        baseHeight = _viewportSize / aspect;
      }

      _baseWidth = baseWidth;
      _baseHeight = baseHeight;

      final tx = (_viewportSize - _baseWidth) / 2;
      final ty = (_viewportSize - _baseHeight) / 2;
      _transformation.value = Matrix4.identity()..translate(tx, ty);

      if (mounted) {
        setState(() => _ready = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ready = true;
          _baseWidth = _viewportSize;
          _baseHeight = _viewportSize;
          _transformation.value = Matrix4.identity();
        });
      }
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  Future<void> _applyCrop() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    ui.Image? renderedImage;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      renderedImage = await boundary.toImage(pixelRatio: 2);
      final data =
          await renderedImage.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted || data == null) return;
      Navigator.of(context).pop(data.buffer.asUint8List());
    } finally {
      renderedImage?.dispose();
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.85;
    return AlertDialog(
      title: Text(context.l10n.profileCropTitle),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.profileCropHint,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: _viewportSize,
              height: _viewportSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    key: _captureKey,
                    child: ClipRect(
                      child: ColoredBox(
                        color: AppColors.surfaceCard,
                        child: _ready
                            ? InteractiveViewer(
                                transformationController: _transformation,
                                minScale: 1,
                                maxScale: 4.5,
                                boundaryMargin: const EdgeInsets.all(180),
                                clipBehavior: Clip.none,
                                constrained: false,
                                child: SizedBox(
                                  width: _baseWidth,
                                  height: _baseHeight,
                                  child: Image.memory(
                                    widget.sourceBytes,
                                    fit: BoxFit.fill,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              )
                            : const Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const IgnorePointer(
                    child: CustomPaint(
                      painter: _AvatarCircleMaskPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _exporting ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton.icon(
          onPressed: (!_ready || _exporting) ? null : _applyCrop,
          icon: _exporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(
            _exporting
                ? context.l10n.profilePreparing
                : context.l10n.profileApply,
          ),
        ),
      ],
    );
  }
}

class _AvatarCircleMaskPainter extends CustomPainter {
  const _AvatarCircleMaskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final overlay = Path()
      ..addRect(rect)
      ..addOval(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      overlay,
      Paint()..color = const Color(0x99000000),
    );
    canvas.drawOval(
      rect.deflate(1),
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
