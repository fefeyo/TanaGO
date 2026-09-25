import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../household/presentation/household_controller.dart';
import '../../map_editor/domain/store_map_key.dart';
import '../../map_editor/presentation/map_editor_controller.dart';
import '../../product_categories/presentation/category_controller.dart';
import '../../shopping_list/presentation/shopping_list_controller.dart';
import '../../stores/presentation/store_controller.dart';
import 'shopping_trip_controller.dart';

class ShoppingSelectionPage extends ConsumerWidget {
  const ShoppingSelectionPage({super.key, required this.storeId});
  final String storeId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hid = ref.watch(householdProvider).requireValue!.id;
    final key = StoreMapKey(householdId: hid, storeId: storeId);
    final trip = ref.watch(shoppingTripProvider(key));
    final eligible = ref.watch(storeShoppingItemsProvider(key));
    final categories = ref.watch(categoriesProvider(hid)).valueOrNull ?? [];
    final store = ref
        .watch(storesProvider(hid))
        .valueOrNull
        ?.where((s) => s.id == storeId)
        .firstOrNull;
    final items = eligible.valueOrNull ?? [];
    final groups = items.map((i) => i.categoryId).toSet();
    final selectedCount =
        items.where((i) => trip.selected.contains(i.id)).length;
    final allCount = ref
            .watch(shoppingListProvider(hid))
            .valueOrNull
            ?.where((i) => !i.isPurchased)
            .length ??
        0;
    return Scaffold(
      appBar: AppBar(title: const Text('これから買うもの')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store?.name ?? '選択した店舗',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text('この店の棚に設定されたカテゴリから選びます。'),
                  if (allCount > items.length && eligible.hasValue)
                    Text(
                      '未分類・この店に未設定の商品 ${allCount - items.length}点は登録一覧に残ります。',
                    ),
                ],
              ),
            ),
            Expanded(
              child: eligible.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: TextButton(
                    onPressed: () {
                      ref.invalidate(mapEditorProvider(key));
                      ref.invalidate(shoppingListProvider(hid));
                    },
                    child: const Text('再読み込み'),
                  ),
                ),
                data: (_) => items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('この店で選べる商品はありません。'),
                            TextButton(
                              onPressed: () =>
                                  context.push('/stores/$storeId/map/edit'),
                              child: const Text('棚のカテゴリを設定する'),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        children: [
                          for (final categoryId in groups)
                            ExpansionTile(
                              key: PageStorageKey('trip-$storeId-$categoryId'),
                              initiallyExpanded: true,
                              title: Text(categoryName(categories, categoryId)),
                              subtitle: Text(
                                '${items.where((i) => i.categoryId == categoryId).length}点',
                              ),
                              children: [
                                for (final item in items
                                    .where((i) => i.categoryId == categoryId))
                                  CheckboxListTile(
                                    key: ValueKey('select-${item.id}'),
                                    title: Text(item.name),
                                    value: trip.selected.contains(item.id),
                                    onChanged: (value) => ref
                                        .read(
                                          shoppingTripProvider(key).notifier,
                                        )
                                        .select(item.id, value ?? false),
                                  ),
                              ],
                            ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selectedCount == 0
                      ? null
                      : () => context.push('/stores/$storeId/map'),
                  child: Text('$selectedCount点を持って店内マップへ'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
