import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/app.dart';
import 'package:tanago/src/features/auth/data/in_memory_auth_repository.dart';
import 'package:tanago/src/features/auth/presentation/auth_controller.dart';
import 'package:tanago/src/features/household/data/in_memory_household_repository.dart';
import 'package:tanago/src/features/household/presentation/household_controller.dart';
import 'package:tanago/src/features/shopping_list/data/in_memory_shopping_list_repository.dart';
import 'package:tanago/src/features/shopping_list/presentation/shopping_list_controller.dart';

void main() {
  testWidgets('starts without Firebase and creates a household',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
          householdRepositoryProvider
              .overrideWithValue(InMemoryHouseholdRepository()),
          shoppingListRepositoryProvider
              .overrideWithValue(InMemoryShoppingListRepository()),
        ],
        child: const TanaGoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('この名前で始める'), findsOneWidget);
    // Tapping and selecting text needs the Navigator's Overlay. Merely
    // rendering the setup page does not exercise this failure.
    final nameField = find.widgetWithText(TextField, '世帯名');
    await tester.tap(nameField);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(nameField, 'テストの家');
    await tester.longPress(nameField);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    final inviteField = find.widgetWithText(TextField, '招待コード');
    await tester.ensureVisible(inviteField);
    await tester.tap(inviteField);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(inviteField, 'TANA-INVALID');
    await tester.longPress(inviteField);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('この名前で始める'));
    await tester.tap(find.text('この名前で始める'));
    await tester.pumpAndSettle();
    expect(find.text('この名前で始める'), findsNothing);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('テストの家'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('わが家'));
    await tester.pumpAndSettle();
    expect(find.text('家族を招待'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('買ってきてほしいもの'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
