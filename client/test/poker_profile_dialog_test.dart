import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/auth/auth_repository.dart';
import 'package:multigames_client/core/presence_provider.dart';
import 'package:multigames_client/games/games_provider.dart';
import 'package:multigames_client/games/games_repository.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/shop/shop_provider.dart';
import 'package:multigames_client/shop/shop_repository.dart';
import 'package:multigames_client/ui/widgets/user_profile_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ShowcaseShop extends ShopRepository {
  _ShowcaseShop() : super(AuthRepository());

  @override
  Future<List<InventoryItem>> listCollectionsShowcase(String userId) async {
    return const [
      InventoryItem(
        code: 'eagle',
        kind: 'collection',
        title: 'Орёл',
        description: '',
        payload: {'emoji': '🦅'},
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('карточка соперника показывает профиль, а не только коллекции',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profilePresenceProvider.overrideWith((ref, id) async => null),
          headToHeadProvider.overrideWith(
            (ref, id) async => HeadToHead(
              opponentId: id,
              displayName: 'Аня',
              won: 0,
              drawn: 0,
              lost: 0,
            ),
          ),
          shopRepositoryProvider.overrideWith((ref) => _ShowcaseShop()),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: _OpenProfile()),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Аня'), findsOneWidget);
    expect(find.text('О себе'), findsOneWidget);
    expect(find.text('играю по вечерам'), findsOneWidget);
    expect(find.text('27 лет'), findsOneWidget);
    expect(find.byIcon(Icons.female_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.text('Коллекции'), findsOneWidget);
  });
}

class _OpenProfile extends ConsumerWidget {
  const _OpenProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () {
        showUserProfileDialog(
          context: context,
          ref: ref,
          userId: 'opponent-1',
          displayName: 'Аня',
          age: 27,
          gender: 'female',
          about: 'играю по вечерам',
        );
      },
      child: const Text('open'),
    );
  }
}
