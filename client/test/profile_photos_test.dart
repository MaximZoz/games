import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/l10n/display_names.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/profile/profile_gallery_widgets.dart';
import 'package:multigames_client/profile/profile_photos.dart';

void main() {
  test('ProfilePhotoMeta.fromJson читает слот и id', () {
    final photo = ProfilePhotoMeta.fromJson({
      'id': 'p1',
      'user_id': 'u1',
      'slot': 2,
      'image_mime': 'image/png',
    });
    expect(photo.id, 'p1');
    expect(photo.userId, 'u1');
    expect(photo.slot, 2);
    expect(photo.imageMime, 'image/png');
  });

  test('profilePhotoSlots раскладывает до 3 слотов', () {
    final photos = [
      const ProfilePhotoMeta(
        id: 'a',
        userId: 'u',
        slot: 1,
        imageMime: 'image/jpeg',
      ),
    ];
    final slots = profilePhotoSlots(photos);
    expect(slots, hasLength(maxProfilePhotos));
    expect(slots[0], isNull);
    expect(slots[1]?.id, 'a');
    expect(slots[2], isNull);
  });

  test('profilePhotosSignature меняется после добавления фото', () {
    const empty = <ProfilePhotoMeta>[];
    const one = [
      ProfilePhotoMeta(
        id: 'p1',
        userId: 'u',
        slot: 0,
        imageMime: 'image/jpeg',
      ),
    ];
    expect(profilePhotosSignature(empty), '');
    expect(profilePhotosSignature(one), '0:p1');
    expect(profilePhotosSignature(empty), isNot(profilePhotosSignature(one)));
    expect(
      profilePhotosSignature(one),
      profilePhotosSignature([
        const ProfilePhotoMeta(
          id: 'p1',
          userId: 'u',
          slot: 0,
          imageMime: 'image/jpeg',
        ),
      ]),
    );
  });

  test('свободный слот для оригинала аватара — первый пустой', () {
    expect(profilePhotoSlots(const []).indexWhere((e) => e == null), 0);
    expect(
      profilePhotoSlots(const [
        ProfilePhotoMeta(
          id: 'p1',
          userId: 'u',
          slot: 0,
          imageMime: 'image/jpeg',
        ),
      ]).indexWhere((e) => e == null),
      1,
    );
    expect(
      profilePhotoSlots(const [
        ProfilePhotoMeta(
          id: 'a',
          userId: 'u',
          slot: 0,
          imageMime: 'image/jpeg',
        ),
        ProfilePhotoMeta(
          id: 'b',
          userId: 'u',
          slot: 1,
          imageMime: 'image/jpeg',
        ),
        ProfilePhotoMeta(
          id: 'c',
          userId: 'u',
          slot: 2,
          imageMime: 'image/jpeg',
        ),
      ]).indexWhere((e) => e == null),
      -1,
    );
  });

  test('profilePhotoSlots игнорирует слот вне диапазона', () {
    final slots = profilePhotoSlots([
      const ProfilePhotoMeta(
        id: 'x',
        userId: 'u',
        slot: 9,
        imageMime: 'image/jpeg',
      ),
    ]);
    expect(slots.every((e) => e == null), isTrue);
  });

  testWidgets('пустые слоты показывают плюс', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfileGallerySlotRow(
            slots: const [null, null, null],
            slotSize: 64,
            imageBuilder: (_) => const SizedBox.shrink(),
            onAddSlot: (_) {},
            onReplaceSlot: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('profile-gallery-slot-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-gallery-slot-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-gallery-slot-2')), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsNWidgets(3));
  });

  testWidgets('заполненный слот без плюса, есть кнопка удаления', (tester) async {
    const photo = ProfilePhotoMeta(
      id: 'p1',
      userId: 'u1',
      slot: 0,
      imageMime: 'image/jpeg',
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfileGallerySlotRow(
            slots: const [photo, null, null],
            slotSize: 64,
            imageBuilder: (_) => const ColoredBox(color: Colors.orange),
            onAddSlot: (_) {},
            onReplaceSlot: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('profile-gallery-slot-add-0')), findsNothing);
    expect(find.byKey(const ValueKey('profile-gallery-slot-add-1')), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  test('isSupportDisplayName ловит служебный аккаунт', () {
    expect(isSupportDisplayName('Поддержка'), isTrue);
    expect(isSupportDisplayName('Support'), isTrue);
    expect(isSupportDisplayName('player1'), isFalse);
  });

  test('isProfileFileAvatar только для загруженного файла', () {
    expect(isProfileFileAvatar('file', 'base64,abc'), isTrue);
    expect(isProfileFileAvatar('letter', 'A'), isFalse);
    expect(isProfileFileAvatar('preset', '3'), isFalse);
    expect(isProfileFileAvatar('file', ''), isFalse);
    expect(isProfileFileAvatar('file', null), isFalse);
  });

  testWidgets('просмотр только аватара-фото — без ленты и без кнопки кропа', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfilePhotoViewerBody(
          photos: const [],
          selectedIndex: 0,
          avatarPhoto: const ColoredBox(
            key: ValueKey('hero'),
            color: Colors.purple,
          ),
          imageBuilder: _emptyImage,
          onSelectIndex: _noop,
          onClose: () {},
        ),
      ),
    );
    expect(find.byKey(const ValueKey('profile-viewer-main')), findsOneWidget);
    expect(find.byKey(const ValueKey('hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-viewer-strip')), findsNothing);
    expect(find.text('Сделать основным'), findsNothing);
  });

  testWidgets('просмотр: аватар-фото первым в ленте, без кнопки кропа', (tester) async {
    const photo = ProfilePhotoMeta(
      id: 'p1',
      userId: 'u1',
      slot: 0,
      imageMime: 'image/jpeg',
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfilePhotoViewerBody(
          photos: const [photo],
          selectedIndex: 0,
          avatarPhoto: const ColoredBox(
            key: ValueKey('hero'),
            color: Colors.purple,
          ),
          avatarThumb: const ColoredBox(
            key: ValueKey('hero-thumb'),
            color: Colors.orange,
          ),
          imageBuilder: (_, {BoxFit fit = BoxFit.cover}) =>
              const ColoredBox(
                key: ValueKey('original-p1'),
                color: Colors.blue,
              ),
          onSelectIndex: _noop,
          onClose: () {},
        ),
      ),
    );
    expect(find.byKey(const ValueKey('profile-viewer-main')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-viewer-strip')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-photo-thumb-avatar')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-photo-thumb-p1')), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.text('Сделать основным'), findsNothing);
  });

  testWidgets('смайл/буква не попадают в ленту — только фото галереи', (tester) async {
    const first = ProfilePhotoMeta(
      id: 'p1',
      userId: 'u1',
      slot: 0,
      imageMime: 'image/jpeg',
    );
    const second = ProfilePhotoMeta(
      id: 'p2',
      userId: 'u1',
      slot: 1,
      imageMime: 'image/jpeg',
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfilePhotoViewerBody(
          photos: const [first, second],
          selectedIndex: 0,
          imageBuilder: (photo, {BoxFit fit = BoxFit.cover}) => ColoredBox(
            key: ValueKey('original-${photo.id}'),
            color: Colors.blue,
          ),
          onSelectIndex: _noop,
          onClose: () {},
        ),
      ),
    );
    expect(find.byKey(const ValueKey('profile-photo-thumb-avatar')), findsNothing);
    expect(find.byKey(const ValueKey('profile-photo-thumb-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-photo-thumb-p2')), findsOneWidget);
    expect(find.text('Сделать основным'), findsNothing);
  });

  testWidgets('лента: тап по аватару возвращает на его фото', (tester) async {
    const first = ProfilePhotoMeta(
      id: 'p1',
      userId: 'u1',
      slot: 0,
      imageMime: 'image/jpeg',
    );
    var index = 1;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatefulBuilder(
          builder: (context, setState) {
            return ProfilePhotoViewerBody(
              photos: const [first],
              selectedIndex: index,
              avatarPhoto: const ColoredBox(
                key: ValueKey('hero'),
                color: Colors.purple,
              ),
              avatarThumb: const ColoredBox(
                key: ValueKey('hero-thumb'),
                color: Colors.purple,
              ),
              imageBuilder: (photo, {BoxFit fit = BoxFit.cover}) => ColoredBox(
                key: ValueKey('original-${photo.id}'),
                color: Colors.blue,
              ),
              onSelectIndex: (i) => setState(() => index = i),
              onClose: () {},
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Сделать основным'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('profile-photo-thumb-avatar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-viewer-main')), findsOneWidget);
    expect(find.byKey(const ValueKey('hero')), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
  });

  testWidgets('слоты сообщают форме о составе фото', (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profilePhotosProvider.overrideWith((ref, userId) async => const []),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProfileGalleryEditSlots(
              userId: 'u1',
              onPhotosChanged: (photos) {
                seen.add(profilePhotosSignature(photos));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(seen, ['']);
  });
}

Widget _emptyImage(ProfilePhotoMeta photo, {BoxFit fit = BoxFit.cover}) {
  return const SizedBox.shrink();
}

void _noop(int index) {}
