import 'package:flutter/material.dart';
import 'package:multigames_client/core/gamepad/gamepad_focus_block.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/widgets/animated_border_box.dart';

/// Карточка-действие в стиле главной (Достижения / Монеты).
class HomeActionCard extends StatelessWidget {
  const HomeActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
    this.dense = false,
    this.onInfoTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;
  /// Компактный вид (телефон landscape на главной).
  final bool dense;
  /// Иконка справки справа, как на карточках игр.
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    final iconSize = dense ? 40.0 : 48.0;
    final padH = dense ? 12.0 : 18.0;
    final padV = dense ? 10.0 : 16.0;
    return GamepadFocusBlock(
      radius: dense ? 18 : 22,
      onActivate: onTap,
      child: AnimatedBorderBox(
      padding: EdgeInsets.zero,
      borderRadius: dense ? 18 : 22,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          canRequestFocus: false,
          onTap: onTap,
          borderRadius: BorderRadius.circular(dense ? 16 : 20),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: Row(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(dense ? 12 : 15),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.accentStart,
                    size: dense ? 22 : 26,
                  ),
                ),
                SizedBox(width: dense ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: dense ? 15 : 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (badgeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$badgeCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: dense ? 2 : 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: dense ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onInfoTap != null)
                  GamepadFocusBlock(
                    radius: 16,
                    shape: GamepadHighlightShape.circle,
                    onActivate: onInfoTap,
                    child: IconButton(
                      onPressed: onInfoTap,
                      tooltip: title,
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(32, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: dense ? 20 : 24,
                  ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
