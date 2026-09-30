import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/product_categories/domain/product_categories.dart';
import 'package:tanago/src/features/shopping_list/domain/shopping_item.dart';
import 'package:tanago/src/features/shopping_list/presentation/category_shopping_list.dart';

ShoppingItem item(
  String id,
  String? category, {
  ShoppingPriority priority = ShoppingPriority.normal,
}) =>
    ShoppingItem(
      id: id,
      name: id,
      categoryId: category,
      priority: priority,
      addedByUid: 'u',
      createdAt: DateTime(2026),
    );

void main() {
  testWidgets(
      'groups by catalog order, sorts priority, and prompts unclassified edits',
      (tester) async {
    ShoppingItem? edited;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryShoppingList(
            items: [
              item('未分類商品', null),
              item('通常の牛乳', 'dairy'),
              item('野菜', 'produce'),
              item('低い卵', 'dairy', priority: ShoppingPriority.low),
              item('急ぎの牛乳', 'dairy', priority: ShoppingPriority.high),
            ],
            categories: productCategories,
            members: const [],
            onEdit: (value) => edited = value,
            onDelete: (_) {},
          ),
        ),
      ),
    );
    double y(String id) => tester.getTopLeft(find.byKey(ValueKey(id))).dy;
    expect(y('野菜'), lessThan(y('急ぎの牛乳')));
    expect(y('急ぎの牛乳'), lessThan(y('通常の牛乳')));
    expect(y('通常の牛乳'), lessThan(y('低い卵')));
    expect(y('低い卵'), lessThan(y('未分類商品')));
    expect(
      tester.getSize(find.byKey(const ValueKey('通常の牛乳'))).height,
      lessThanOrEqualTo(64),
    );
    expect(find.text('カテゴリを設定'), findsOneWidget);
    await tester.tap(find.text('カテゴリを設定'));
    expect(edited?.id, '未分類商品');
  });

  testWidgets('category header stays pinned then yields to the next category',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 350,
            child: CategoryShoppingList(
              items: [
                for (var i = 0; i < 12; i++) item('野菜$i', 'produce'),
                for (var i = 0; i < 12; i++) item('牛乳$i', 'dairy'),
              ],
              categories: productCategories,
              members: const [],
              onEdit: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      ),
    );
    final list = find.byKey(const ValueKey('category-shopping-list'));
    final first = find.byKey(const ValueKey('category-header-produce'));
    final second = find.byKey(const ValueKey('category-header-dairy'));
    final top = tester.getTopLeft(list).dy;
    await tester.drag(list, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(first).dy, closeTo(top, 0.1));
    await tester.drag(list, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(second).dy, closeTo(top, 0.1));
    expect(tester.takeException(), isNull);
  });
}
