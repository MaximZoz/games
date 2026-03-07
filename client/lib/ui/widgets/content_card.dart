import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'gradient_card.dart';

/// Универсальная карточка для контента: игры, друзья, лобби, приглашения и т.д.
/// Градиентный бордер, градиентная тень, адаптивные отступы, поддержка leading/trailing.
class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.child,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    this.margin,
    this.onTap,
    this.animate = false,
    this.borderWidth = 2,
    this.animateBorder = false,
  });

  final Widget child;
  final Widget? leading;
  final String? title;
  final String? subtitle;
  final List<Widget>? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool animate;
  /// Толщина градиентной рамки.
  final double borderWidth;
  /// Циклическая анимация градиента рамки.
  final bool animateBorder;

  /// Адаптивные отступы в зависимости от ширины экрана.
  static EdgeInsets paddingFor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w >= 700;
    final isMedium = w >= 500 && w < 700;
    if (isDesktop) return const EdgeInsets.all(24);
    if (isMedium) return const EdgeInsets.all(18);
    return const EdgeInsets.all(16);
  }

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? paddingFor(context);
    Widget content = child;

    if (leading != null || title != null || trailing != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: title != null || trailing != null ? 12 : 0),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (subtitle != null) ...[
                      if (title != null) const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                ...trailing!,
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: child,
          ),
        ],
      );
    }

    final card = GradientCard(
      margin: margin ?? EdgeInsets.zero,
      padding: effectivePadding,
      animate: animate,
      borderWidth: borderWidth,
      animateBorder: animateBorder,
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: content,
              ),
            )
          : content,
    );

    return card;
  }
}
