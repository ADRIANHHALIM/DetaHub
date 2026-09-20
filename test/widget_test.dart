// test/widget_test.dart
//
// Smoke test for DetaHubApp.
// Verifies that the app initializes with an in-memory database
// and renders the initial Sector screen with the 'DetaHub' title.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:detahub/core/database/app_database.dart';
import 'package:detahub/main.dart';

void main() {
  testWidgets('DetaHubApp smoke test', (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
        child: const DetaHubApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('DetaHub'), findsOneWidget);

    await testDb.close();
  });
}
