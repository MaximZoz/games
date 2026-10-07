import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/shop/elixir_icon.dart';
import 'package:multigames_client/shop/elixir_labels.dart';

void main() {
  testWidgets('флаконы эликсиров рисуются', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              ElixirIcon(set: 'celebration', effect: 'rejuvenate', size: 48),
              ElixirIcon(set: 'nature', effect: 'age', size: 48),
              ElixirIcon(set: 'legends', effect: 'accelerate', size: 48),
              ElixirIcon(set: 'cosmic', effect: 'rejuvenate', size: 48),
              ElixirIcon(set: 'adventure', effect: 'age', size: 48),
              ElixirIcon(set: 'jewels', effect: 'accelerate', size: 48),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(ElixirIcon), findsNWidgets(6));
    expect(elixirEffectOrder, hasLength(3));
    expect(elixirSetOrder, hasLength(6));
  });
}
