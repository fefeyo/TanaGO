import 'package:flutter/material.dart';
import '../../../design/app_components.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../household/presentation/my_name_card.dart';
import '../../household/presentation/household_controller.dart';
import '../../product_categories/presentation/category_controller.dart';
import 'shopping_item_dialog.dart';
import 'category_shopping_list.dart';
import 'shopping_list_controller.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider).requireValue!;
    final asyncItems = ref.watch(shoppingListProvider(household.id));
    final asyncCategories = ref.watch(categoriesProvider(household.id));
    final categories = asyncCategories.valueOrNull ?? [];
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            MyNameCard(householdId: household.id, onlyWhenMissing: true),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PageBanner(
                eyebrow: household.name,
                title: '${items.length}点の買いたいもの',
                icon: Icons.home_outlined,
                description: '家族の「買ってきて」を、ひとつに。',
                trailing: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE7F0CD),
                    foregroundColor: const Color(0xFF214C36),
                  ),
                  onPressed: () =>
                      showShoppingItemDialog(context, household.id),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('登録'),
                ),
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
                data: (_) => !asyncCategories.hasValue
                    ? Center(
                        child: asyncCategories.hasError
                            ? TextButton(
                                onPressed: () => ref.invalidate(
                                  categoriesProvider(household.id),
                                ),
                                child: const Text('カテゴリを再読み込み'),
                              )
                            : const CircularProgressIndicator(),
                      )
                    : items.isEmpty
                        ? const EmptyState(
                            icon: Icons.shopping_basket_outlined,
                            message: '買いたいものを登録して\n家族と共有しましょう',
                          )
                        : CategoryShoppingList(
                            items: items,
                            categories: categories,
                            onEdit: (item) => showShoppingItemDialog(
                              context,
                              household.id,
                              item: item,
                            ),
                            onDelete: (item) async {
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
