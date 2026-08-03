import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/auth/auth_provider.dart';
import 'package:multigames_client/auth/referral_link.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';
import 'package:multigames_client/ui/widgets/coin_icon.dart';
import 'package:multigames_client/ui/widgets/swipe_back.dart';

class CoinsFriendScreen extends ConsumerStatefulWidget {
  const CoinsFriendScreen({super.key});

  @override
  ConsumerState<CoinsFriendScreen> createState() => _CoinsFriendScreenState();
}

class _CoinsFriendScreenState extends ConsumerState<CoinsFriendScreen> {
  bool _linkCopied = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(authStateProvider).valueOrNull;
    void goBack() => context.pop();

    return SwipeBackScope(
      onBack: goBack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: goBack,
            tooltip: l10n.commonBack,
          ),
          title: Text(
            l10n.coinsFriendReward,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: useDesktopTiles(context) ? 520 : 480,
              ),
              child: user == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.accentSoft
                                            .withValues(alpha: 0.7),
                                      ),
                                      alignment: Alignment.center,
                                      child: const CoinIcon(
                                        coinType: CoinType.bronze,
                                        size: 30,
                                        animate: true,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.coinsInviteFriend,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.coinsInviteHint(
                                              formatRewardBronze(
                                                referralBonusBronze,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentSoft
                                        .withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SelectableText(
                                    buildReferralShareUrl(
                                      userId: user.id,
                                      baseUri: Uri.base,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () async {
                                      final url = buildReferralShareUrl(
                                        userId: user.id,
                                        baseUri: Uri.base,
                                      );
                                      await Clipboard.setData(
                                        ClipboardData(text: url),
                                      );
                                      if (!mounted) return;
                                      setState(() => _linkCopied = true);
                                    },
                                    icon: Icon(
                                      _linkCopied
                                          ? Icons.check_rounded
                                          : Icons.link_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _linkCopied
                                          ? l10n.commonCopied
                                          : l10n.coinsCopyLink,
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.accentStart,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.coinsHowItWorks,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _FriendStep(
                            number: '1',
                            text: l10n.coinsHowStep1,
                          ),
                          _FriendStep(
                            number: '2',
                            text: l10n.coinsHowStep2,
                          ),
                          _FriendStep(
                            number: '3',
                            text: l10n.coinsHowStep3(
                              formatRewardBronze(referralBonusBronze),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendStep extends StatelessWidget {
  const _FriendStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accentStart,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
