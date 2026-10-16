import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/ui/widgets/game_screen_widgets.dart';

void main() {
  setUp(PlayerAvatarMemory.clear);
  tearDown(PlayerAvatarMemory.clear);

  testWidgets('preset stays when the next snapshot has no portrait',
      (tester) async {
    final key = GlobalKey<_AvatarHarnessState>();
    await tester.pumpWidget(_AvatarHarness(key: key));
    expect(find.byIcon(Icons.face_rounded), findsOneWidget);

    key.currentState!.setPortrait(kind: 'letter', value: null);
    await tester.pump();
    expect(find.byIcon(Icons.face_rounded), findsOneWidget);

    key.currentState!.setPortrait(kind: 'preset', value: '1');
    await tester.pump();
    expect(find.byIcon(Icons.face_2_rounded), findsOneWidget);
    expect(find.byIcon(Icons.face_rounded), findsNothing);
  });

  testWidgets('a recreated seat keeps the last portrait for the same player',
      (tester) async {
    await tester.pumpWidget(
      const _AvatarApp(
        userId: 'u1',
        displayName: 'Анна',
        avatarKind: 'preset',
        avatarValue: '0',
      ),
    );
    expect(find.byIcon(Icons.face_rounded), findsOneWidget);

    await tester.pumpWidget(
      const _AvatarApp(
        userId: 'u1',
        displayName: 'Анна',
        avatarKind: 'letter',
      ),
    );
    expect(find.byIcon(Icons.face_rounded), findsOneWidget);
  });

  testWidgets('switching players does not reuse the previous portrait',
      (tester) async {
    final key = GlobalKey<_AvatarHarnessState>();
    await tester.pumpWidget(_AvatarHarness(key: key));
    expect(find.byIcon(Icons.face_rounded), findsOneWidget);

    key.currentState!.setPortrait(
      userId: 'u2',
      displayName: 'Борис',
      kind: 'letter',
      value: null,
    );
    await tester.pump();
    expect(find.byIcon(Icons.face_rounded), findsNothing);
    expect(find.text('Б'), findsOneWidget);
  });
}

class _AvatarHarness extends StatefulWidget {
  const _AvatarHarness({super.key});

  @override
  State<_AvatarHarness> createState() => _AvatarHarnessState();
}

class _AvatarHarnessState extends State<_AvatarHarness> {
  String? userId = 'u1';
  String displayName = 'Анна';
  String kind = 'preset';
  String? value = '0';

  void setPortrait({
    String? userId,
    String? displayName,
    required String kind,
    required String? value,
  }) {
    setState(() {
      if (userId != null) this.userId = userId;
      if (displayName != null) this.displayName = displayName;
      this.kind = kind;
      this.value = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AvatarApp(
      userId: userId,
      displayName: displayName,
      avatarKind: kind,
      avatarValue: value,
    );
  }
}

class _AvatarApp extends StatelessWidget {
  const _AvatarApp({
    required this.userId,
    required this.displayName,
    required this.avatarKind,
    this.avatarValue,
  });

  final String? userId;
  final String displayName;
  final String avatarKind;
  final String? avatarValue;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: GamePlayerAvatar(
          userId: userId,
          displayName: displayName,
          avatarKind: avatarKind,
          avatarValue: avatarValue,
        ),
      ),
    );
  }
}
