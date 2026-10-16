import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigames_client/core/native_app_link.dart';
import 'package:multigames_client/core/native_app_link_stub.dart'
    if (dart.library.html) 'package:multigames_client/core/native_app_link_web.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/router.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';

/// На телефоне в браузере: лобби по https открывает установленное приложение.
///
/// Полоска живёт вне [GoRouter] (builder MaterialApp оборачивает роутер снаружи),
/// поэтому адрес берётся из [goRouterProvider], а не из `GoRouter.of`.
class OpenInAppBanner extends ConsumerStatefulWidget {
  const OpenInAppBanner({super.key});

  @override
  ConsumerState<OpenInAppBanner> createState() => _OpenInAppBannerState();
}

class _OpenInAppBannerState extends ConsumerState<OpenInAppBanner> {
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _hidden = nativeAppBannerDismissed();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _hidden) return const _BannerHole();
    final router = ref.watch(goRouterProvider);
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final uri = _currentUri(router);
        if (uri == null || !isNarrow(context) || browserIsStandalone()) {
          return const _BannerHole();
        }
        final handoff = nativeAppHandoffFor(
          page: uri,
          userAgent: browserUserAgent(),
        );
        if (handoff == null) return const _BannerHole();
        final l10n = context.l10n;
        final top = MediaQuery.paddingOf(context).top + 8;
        return Positioned(
          left: 12,
          right: 12,
          top: top,
          child: Material(
            elevation: 8,
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => openNativeAppHandoff(handoff),
                      child: Text(
                        l10n.openInApp,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.commonClose,
                    onPressed: () {
                      dismissNativeAppBanner();
                      setState(() => _hidden = true);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Uri? _currentUri(GoRouter router) {
  try {
    return router.routerDelegate.currentConfiguration.uri;
  } catch (_) {
    return null;
  }
}

/// Пустой positioned-ребёнок: Stack с одним Positioned.fill иначе схлопывается,
/// а непозиционированный shrink при expand перехватывает нажатия.
class _BannerHole extends StatelessWidget {
  const _BannerHole();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      left: 0,
      top: 0,
      width: 0,
      height: 0,
      child: SizedBox.shrink(),
    );
  }
}
