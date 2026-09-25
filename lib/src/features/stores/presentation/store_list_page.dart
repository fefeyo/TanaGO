import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../household/presentation/household_controller.dart';
import '../domain/store.dart';
import 'store_controller.dart';

class StoreListPage extends ConsumerWidget {
  const StoreListPage({super.key, this.shopping = false});
  final bool shopping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider).valueOrNull!;
    final storesAsync = ref.watch(storesProvider(household.id));
    final stores = storesAsync.valueOrNull ?? const <Store>[];

    return Scaffold(
      appBar: AppBar(title: Text(shopping ? '買い物する店舗を選ぶ' : '店舗を管理')),
      body: storesAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : storesAsync.hasError
              ? Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(storesProvider(household.id)),
                    child: const Text('店舗を再読み込み'),
                  ),
                )
              : stores.isEmpty
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
                            subtitle: Text(
                              shopping ? 'この店で買うものを選ぶ' : '店内マップと棚のカテゴリを編集',
                            ),
                            trailing: IconButton(
                              tooltip: '店内マップを編集',
                              onPressed: () =>
                                  context.push('/stores/${store.id}/map/edit'),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            onTap: () => context.push(
                              '/stores/${store.id}/${shopping ? 'select' : 'map/edit'}',
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _AddStoreDialog(householdId: household.id),
        ),
        icon: const Icon(Icons.add_business),
        label: const Text('店舗を追加'),
      ),
    );
  }
}

class _AddStoreDialog extends ConsumerStatefulWidget {
  const _AddStoreDialog({required this.householdId});
  final String householdId;
  @override
  ConsumerState<_AddStoreDialog> createState() => _AddStoreDialogState();
}

class _AddStoreDialogState extends ConsumerState<_AddStoreDialog> {
  final _name = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = '店舗名を入力してください');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(storeControllerProvider(widget.householdId))
          .add(_name.text);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '店舗を保存できませんでした';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('店舗を追加'),
        content: TextField(
          controller: _name,
          enabled: !_saving,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(
            labelText: '店舗名',
            hintText: '例：○○スーパー',
            errorText: _error,
          ),
          onSubmitted: (_) => _save(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中…' : '追加'),
          ),
        ],
      );
}
