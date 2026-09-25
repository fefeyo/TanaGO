import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../household/domain/household.dart';
import '../../household/presentation/household_controller.dart';
import '../../product_categories/presentation/category_controller.dart';
import 'shopping_item_dialog.dart';
import 'shopping_list_controller.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider).requireValue!;
    final asyncItems = ref.watch(shoppingListProvider(household.id));
    final members =
        ref.watch(householdMembersProvider(household.id)).valueOrNull ??
            <HouseholdMember>[];
    final categories =
        ref.watch(categoriesProvider(household.id)).valueOrNull ?? [];
    final items =
        asyncItems.valueOrNull?.where((i) => !i.isPurchased).toList() ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('買いたいもの'),
        actions: [
          IconButton(
            tooltip: 'カテゴリ',
            onPressed: () => context.push('/categories'),
            icon: const Icon(Icons.category_outlined),
          ),
          IconButton(
            tooltip: '店舗を管理',
            onPressed: () => context.push('/stores'),
            icon: const Icon(Icons.storefront_outlined),
          ),
          IconButton(
            tooltip: 'わが家',
            onPressed: () => context.push('/household'),
            icon: const Icon(Icons.group_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(household.name),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${items.length}点の買いたいもの',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        showShoppingItemDialog(context, household.id),
                    icon: const Icon(Icons.add),
                    label: const Text('登録'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: asyncItems.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(shoppingListProvider(household.id)),
                    child: const Text('リストを再読み込み'),
                  ),
                ),
                data: (_) => items.isEmpty
                    ? const Center(
                        child: Text(
                          '買いたいものを登録して\n家族と共有しましょう',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            key: ValueKey(item.id),
                            title: Text(item.name),
                            subtitle: Text(
                              '${categoryName(categories, item.categoryId)} ・ ${memberName(members, item.addedByUid)}が登録',
                            ),
                            onTap: () => showShoppingItemDialog(
                              context,
                              household.id,
                              item: item,
                            ),
                            trailing: IconButton(
                              tooltip: '削除',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final remove = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: Text(
                                      '${item.name}を削除しますか？',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                          c,
                                          false,
                                        ),
                                        child: const Text(
                                          'キャンセル',
                                        ),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(
                                          c,
                                          true,
                                        ),
                                        child: const Text('削除'),
                                      ),
                                    ],
                                  ),
                                );
                                if (remove != true || !context.mounted) {
                                  return;
                                }
                                try {
                                  await ref
                                      .read(
                                        shoppingListControllerProvider(
                                          household.id,
                                        ),
                                      )
                                      .remove(item.id);
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('削除できませんでした'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: items.isEmpty
                      ? null
                      : () => context.push('/stores?shopping=true'),
                  icon: const Icon(Icons.shopping_basket_outlined),
                  label: const Text('買い物に行く'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
