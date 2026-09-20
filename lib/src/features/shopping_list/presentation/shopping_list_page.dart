import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../household/presentation/household_controller.dart';
import '../../product_categories/domain/product_categories.dart';
import 'shopping_list_controller.dart';

class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(householdProvider);
    final items = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TanaGO'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              household.name,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: '買ってきてほしいもの',
                        hintText: '例: 牛乳',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          '買ってきてほしいものを追加すると\n同じ家のメンバーと共有できます',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Dismissible(
                            key: ValueKey(item.id),
                            onDismissed: (_) => ref
                                .read(shoppingListProvider.notifier)
                                .remove(item.id),
                            child: CheckboxListTile(
                              value: item.isPurchased,
                              title: Text(item.name),
                              subtitle: Text(
                                _itemSubtitle(
                                  item.isPurchased,
                                  item.categoryId,
                                ),
                              ),
                              secondary: IconButton(
                                tooltip: 'カテゴリを設定',
                                onPressed: () => _showCategoryPicker(
                                  item.id,
                                  item.categoryId,
                                ),
                                icon: Icon(
                                  item.categoryId == null
                                      ? Icons.category_outlined
                                      : Icons.category,
                                ),
                              ),
                              onChanged: (_) => ref
                                  .read(shoppingListProvider.notifier)
                                  .togglePurchased(item.id),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: items.isEmpty
                      ? null
                      : () => context.push('/stores'),
                  icon: const Icon(Icons.storefront),
                  label: const Text('買い物に行く'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _itemSubtitle(bool isPurchased, String? categoryId) {
    final category = productCategoryById(categoryId);
    final status = isPurchased ? '購入済み' : 'あなたが追加';
    if (category == null) {
      return '$status ・ カテゴリ未設定';
    }
    return '$status ・ ${category.name}';
  }

  Future<void> _showCategoryPicker(
    String itemId,
    String? selectedCategoryId,
  ) async {
    final categoryId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              '商品カテゴリ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('このカテゴリを使って、店舗内の売り場を表示します。'),
            const SizedBox(height: 12),
            for (final category in productCategories)
              ListTile(
                leading: Icon(
                  category.id == selectedCategoryId
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                ),
                title: Text(category.name),
                onTap: () => Navigator.of(context).pop(category.id),
              ),
          ],
        ),
      ),
    );

    if (categoryId != null) {
      ref
          .read(shoppingListProvider.notifier)
          .updateCategory(itemId, categoryId);
    }
  }

  void _addItem() {
    ref.read(shoppingListProvider.notifier).add(_controller.text);
    _controller.clear();
  }
}
