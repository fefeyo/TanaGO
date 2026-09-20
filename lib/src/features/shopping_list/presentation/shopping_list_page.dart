import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../household/presentation/household_controller.dart';
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
                                item.isPurchased
                                    ? '購入済み'
                                    : 'あなたが追加',
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

  void _addItem() {
    ref.read(shoppingListProvider.notifier).add(_controller.text);
    _controller.clear();
  }
}
