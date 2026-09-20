import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../household/presentation/household_controller.dart';
import '../domain/store.dart';
import 'store_controller.dart';

class StoreListPage extends ConsumerWidget {
  const StoreListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider).valueOrNull!;
    final storesAsync = ref.watch(storesProvider(household.id));
    final stores = storesAsync.valueOrNull ?? const <Store>[];

    return Scaffold(
      appBar: AppBar(title: const Text('店舗を選ぶ')),
      body: stores.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'まだ店舗がありません。\nよく行くスーパーを登録しましょう。',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: stores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final store = stores[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront),
                    title: Text(store.name),
                    subtitle: const Text('店内マップで売り場を確認'),
                    trailing: IconButton(
                      tooltip: '店内マップを編集',
                      onPressed: () =>
                          context.push('/stores/${store.id}/map/edit'),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    onTap: () => context.push('/stores/${store.id}/map'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStoreDialog(context, ref, household.id),
        icon: const Icon(Icons.add_business),
        label: const Text('店舗を追加'),
      ),
    );
  }

  Future<void> _showAddStoreDialog(
    BuildContext context,
    WidgetRef ref,
    String householdId,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗を追加'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '店舗名',
            hintText: '例: ○○スーパー △△店',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('追加'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name != null) {
      ref.read(storeControllerProvider(householdId)).add(name);
    }
  }
}
