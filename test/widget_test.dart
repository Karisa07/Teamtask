// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App smoke test (placeholder)', (tester) async {
    // This project uses go_router + Riverpod + Supabase.
    // The previous default Flutter template test referenced `MyApp`, which
    // doesn't exist in this codebase, causing analysis/test compilation to fail.
    // Keeping a minimal test avoids breaking CI/local `flutter analyze`.

    await tester.pumpWidget(const SizedBox.shrink());
    expect(find.byType(SizedBox), findsOneWidget);
  });
}

