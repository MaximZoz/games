import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:multigames_client/shop/emoji_asset_catalog.dart';
import 'package:multigames_client/shop/flag_emojis.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Токен сообщения с анимированным смайликом: `[ae:rocket]`.
final RegExp animatedEmojiTokenRe = RegExp(r'^\[ae:([A-Za-z0-9_]+)\]$');

String encodeAnimatedEmojiMessage(String animatedName) => '[ae:$animatedName]';

String? parseAnimatedEmojiName(String body) {
  final m = animatedEmojiTokenRe.firstMatch(body.trim());
  return m?.group(1);
}

bool isAnimatedEmojiMessage(String body) =>
    parseAnimatedEmojiName(body) != null;

/// Юникод-символ по имени анимации (из `assets/emojis/`, без сети).
String? unicodeEmojiFromAnimatedName(String name) {
  final flag = countryFlagUnicodeFromName(name);
  if (flag != null) return flag;
  return kBundledEmojiUnicode[name];
}

/// Токен подарка коллекции: `[gift_coll:code|Title|emoji|animatedName]`.
final RegExp giftCollectionTokenRe = RegExp(
  r'^\[gift_coll:([^|\]]+)\|([^|\]]*)\|([^|\]]*)\|([^\]]*)\]$',
);

({String code, String title, String emoji, String animatedName})?
    parseGiftCollectionMessage(String body) {
  final m = giftCollectionTokenRe.firstMatch(body.trim());
  if (m == null) return null;
  return (
    code: m.group(1)!.trim(),
    title: m.group(2)!.trim(),
    emoji: m.group(3)!.trim(),
    animatedName: m.group(4)!.trim(),
  );
}

bool isGiftCollectionMessage(String body) =>
    parseGiftCollectionMessage(body) != null;

String encodeGiftCollectionMessage({
  required String code,
  required String title,
  required String emoji,
  required String animatedName,
}) {
  final safeTitle = title.replaceAll('|', '/').replaceAll(']', '');
  final safeEmoji = emoji.replaceAll('|', '').replaceAll(']', '');
  final safeName = animatedName.replaceAll('|', '').replaceAll(']', '');
  return '[gift_coll:$code|$safeTitle|$safeEmoji|$safeName]';
}

/// Превью текста сообщения: `[ae:smile]` → 😀, подарок → 🎁 Название.
String formatChatMessagePreview(String body) {
  final gift = parseGiftCollectionMessage(body);
  if (gift != null) {
    final title = gift.title.isNotEmpty ? gift.title : 'коллекция';
    final emoji = gift.emoji.isNotEmpty
        ? gift.emoji
        : (unicodeEmojiFromAnimatedName(gift.animatedName) ?? '🎁');
    return '🎁 $emoji $title';
  }
  final name = parseAnimatedEmojiName(body);
  if (name == null) return body;
  return unicodeEmojiFromAnimatedName(name) ?? '🙂';
}

String resolvedEmojiChar(String animatedName, String? fallback) {
  final fromName = unicodeEmojiFromAnimatedName(animatedName);
  if (fromName != null) return fromName;
  final fb = fallback?.trim();
  if (fb != null && fb.isNotEmpty && parseAnimatedEmojiName(fb) == null) {
    return fb;
  }
  return '🙂';
}

/// Плейсхолдер фиксированного размера — без скачков layout при подгрузке.
class EmojiIconPlaceholder extends StatelessWidget {
  const EmojiIconPlaceholder({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final stroke = (size * 0.08).clamp(1.5, 2.5);
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SizedBox(
          width: size * 0.42,
          height: size * 0.42,
          child: CircularProgressIndicator(
            strokeWidth: stroke,
            color: AppColors.accentStart.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

/// Нейтральная иконка группы смайликов (не превью первого товара).
class ShopEmojiGroupIcon extends StatelessWidget {
  const ShopEmojiGroupIcon({
    super.key,
    required this.group,
    this.size = 40,
  });

  final String group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = switch (group) {
      'flags' => Icons.flag_rounded,
      'game' => Icons.sports_esports_rounded,
      'emotions' => Icons.emoji_emotions_rounded,
      _ => Icons.auto_awesome_rounded,
    };
    return _NeutralGroupBadge(
      size: size,
      child: Icon(
        icon,
        size: size * 0.58,
        color: AppColors.accentStart,
      ),
    );
  }
}

class _NeutralGroupBadge extends StatelessWidget {
  const _NeutralGroupBadge({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(
            color: AppColors.accentStart.withValues(alpha: 0.22),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// PNG-флаг из бандла приложения с лоадером на время декодирования.
class CountryFlagImage extends StatelessWidget {
  const CountryFlagImage({
    super.key,
    required this.iso,
    required this.size,
    this.fallbackUnicode,
  });

  final String iso;
  final double size;
  final String? fallbackUnicode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        countryFlagAssetPath(iso),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return EmojiIconPlaceholder(size: size);
        },
        errorBuilder: (context, error, stackTrace) {
          final fb = (fallbackUnicode ?? '').trim();
          if (fb.isNotEmpty) {
            return Center(
              child: Text(fb, style: TextStyle(fontSize: size * 0.72)),
            );
          }
          return Icon(
            Icons.flag_outlined,
            size: size * 0.7,
            color: AppColors.textSecondary,
          );
        },
      ),
    );
  }
}

/// Виджет смайлика из `client/assets/emojis/` (Lottie + unicode, без сети).
///
/// Каталог магазина и владение — на бэкенде; ассеты рисуются локально.
/// Пока ассет не готов — [EmojiIconPlaceholder]. В списках: [animate]=false.
class ShopAnimatedEmoji extends StatefulWidget {
  const ShopAnimatedEmoji({
    super.key,
    required this.animatedName,
    this.size = 32,
    this.fallback,
    this.animate = false,
  });

  final String animatedName;
  final double size;
  final String? fallback;
  final bool animate;

  @override
  State<ShopAnimatedEmoji> createState() => _ShopAnimatedEmojiState();
}

class _ShopAnimatedEmojiState extends State<ShopAnimatedEmoji> {
  bool _ready = false;
  bool _failed = false;
  Timer? _loadTimeout;

  @override
  void initState() {
    super.initState();
    _scheduleStaticReveal();
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ShopAnimatedEmoji oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animatedName != widget.animatedName ||
        oldWidget.animate != widget.animate ||
        oldWidget.size != widget.size) {
      _loadTimeout?.cancel();
      _ready = false;
      _failed = false;
      _scheduleStaticReveal();
    }
  }

  void _scheduleStaticReveal() {
    // Флаги грузятся через Image.asset со своим frameBuilder.
    if (isCountryFlagAnimatedName(widget.animatedName)) {
      return;
    }
    final useLottie =
        widget.animate && hasBundledEmojiLottie(widget.animatedName);
    if (useLottie) {
      _loadTimeout?.cancel();
      _loadTimeout = Timer(const Duration(milliseconds: 2500), () {
        if (!mounted || _ready) return;
        _markFailed();
      });
      return;
    }
    // Статичный unicode: один кадр лоадера, затем fade-in — без мигания
    // «битых» глифов до готовности текстового layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _ready) return;
      setState(() => _ready = true);
    });
  }

  void _markReady() {
    if (!mounted || _ready) return;
    _loadTimeout?.cancel();
    setState(() => _ready = true);
  }

  void _markFailed() {
    if (!mounted) return;
    _loadTimeout?.cancel();
    setState(() {
      _failed = true;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final flagIso = countryFlagIsoFromName(widget.animatedName);
    if (flagIso != null) {
      return CountryFlagImage(
        iso: flagIso,
        size: widget.size,
        fallbackUnicode:
            countryFlagUnicodeFromName(widget.animatedName) ?? widget.fallback,
      );
    }

    final fb = resolvedEmojiChar(widget.animatedName, widget.fallback);
    final staticChild = FittedBox(
      fit: BoxFit.contain,
      child: Text(
        fb,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: widget.size,
          height: 1.0,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
    );

    if (!widget.animate || _failed) {
      if (!_ready) {
        return EmojiIconPlaceholder(size: widget.size);
      }
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(child: staticChild),
      );
    }

    if (!hasBundledEmojiLottie(widget.animatedName)) {
      if (!_ready) {
        return EmojiIconPlaceholder(size: widget.size);
      }
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(child: staticChild),
      );
    }

    // Lottie из client/assets/emojis/lottie/ — без сети и без package assets.
    final lottieSize = widget.size * 0.92;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (!_ready) EmojiIconPlaceholder(size: widget.size),
          Opacity(
            opacity: _ready ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_ready,
              child: Lottie.asset(
                bundledEmojiLottieAsset(widget.animatedName),
                width: lottieSize,
                height: lottieSize,
                repeat: true,
                animate: true,
                onLoaded: (_) => _markReady(),
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _markFailed();
                  });
                  return staticChild;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
