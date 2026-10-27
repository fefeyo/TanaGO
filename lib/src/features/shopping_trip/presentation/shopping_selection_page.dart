import 'package:flutter/material.dart';
import '../../../design/app_components.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../household/presentation/household_controller.dart';
import '../../map_editor/domain/store_map_key.dart';
import '../../map_editor/domain/map_object.dart';
import '../../shopping_list/domain/shopping_item.dart';
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
    final map = ref.watch(mapEditorProvider(key));
    final mapped = (map.valueOrNull ?? <MapObject>[])
        .where((o) => o.type == MapObjectType.shelf)
        .expand((o) => o.categoryIds)
        .toSet();
    final groups = <String?, List<ShoppingItem>>{};
    for (final item in items) {
      final group = mapped.contains(item.categoryId) ? item.categoryId : null;
      (groups[group] ??= []).add(item);
    }
    final order = [
      for (final c in categories)
        if (groups.containsKey(c.id)) c.id,
      for (final id in groups.keys)
        if (id != null && !categories.any((c) => c.id == id)) id,
      if (groups.containsKey(null)) null,
    ];
    for (final values in groups.values) {
      values.sort((a, b) => (a.buySoon ? 0 : 1).compareTo(b.buySoon ? 0 : 1));
    }
    final selectedCount =
        items.where((i) => trip.selected.contains(i.id)).length;
    return Scaffold(
      appBar: AppBar(title: const Text('これから買うもの')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: PageBanner(
                eyebrow: '今日の買い物 / $selectedCount点を選択中',
                title: store?.name ?? '選択した店舗',
                icon: Icons.shopping_basket_outlined,
                description: '売り場ごとに、今回買うものを選びます。場所未登録の商品も選べます。',
              ),
            ),
            if (map.hasError)
              TextButton(
                onPressed: () => ref.invalidate(mapEditorProvider(key)),
                child: const Text('売り場情報を再読み込み（商品は選べます）'),
              ),
            if (map.isLoading) const LinearProgressIndicator(),
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
                            const Text('買いたいものがまだ登録されていません。'),
                            TextButton(
                              onPressed: () => context.go('/'),
                              child: const Text('買いたいものを登録する'),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final categoryId in order)
                            Card(
                              child: ExpansionTile(
                                leading: CategorySymbol(categoryId: categoryId),
                                key:
                                    PageStorageKey('trip-$storeId-$categoryId'),
                                initiallyExpanded: true,
                                title: Text(
                                  categoryId == null
                                      ? '場所未登録'
                                      : categoryName(categories, categoryId),
                                ),
                                subtitle: Text(
                                  '${groups[categoryId]!.length}点${categoryId == null ? '・売り場がまだわからない商品' : ''}',
                                ),
                                children: [
                                  for (final item in groups[categoryId]!)
                                    CheckboxListTile(
                                      key: ValueKey('select-${item.id}'),
                                      title: Text(item.name),
                                      subtitle: item.shoppingDetails.isEmpty
                                          ? null
                                          : Text(item.shoppingDetails),
                                      value: trip.selected.contains(item.id),
                                      onChanged: (value) => ref
                                          .read(
                                            shoppingTripProvider(key).notifier,
                                          )
                                          .select(item.id, value ?? false),
                                    ),
                                ],
                              ),
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
