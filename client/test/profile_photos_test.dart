import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('кнопка «Сделать основным» только у владельца', (tester) async {
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
          body: ProfilePhotosGalleryBody(
            photos: const [photo],
            canManage: true,
            imageBuilder: (_, {BoxFit fit = BoxFit.cover}) =>
                const ColoredBox(color: Colors.blue),
            onOpenPhoto: (_) {},
            onMakePrimary: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Сделать основным'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-make-primary-p1')), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfilePhotosGalleryBody(
            photos: const [photo],
            canManage: false,
            imageBuilder: (_, {BoxFit fit = BoxFit.cover}) =>
                const ColoredBox(color: Colors.blue),
            onOpenPhoto: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Сделать основным'), findsNothing);
  });

  testWidgets('пустая галерея показывает заглушку', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: ProfilePhotosGalleryBody(
            photos: [],
            canManage: false,
            imageBuilder: _emptyImage,
            onOpenPhoto: _noop,
          ),
        ),
      ),
    );
    expect(find.text('Пока нет фото'), findsOneWidget);
  });
}

Widget _emptyImage(ProfilePhotoMeta photo, {BoxFit fit = BoxFit.cover}) {
  return const SizedBox.shrink();
}

void _noop(int index) {}
