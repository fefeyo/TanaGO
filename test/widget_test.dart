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
    await tester.tap(find.text('この名前で始める'));
    await tester.pumpAndSettle();
    expect(find.text('この名前で始める'), findsNothing);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
