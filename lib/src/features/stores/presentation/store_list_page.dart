import 'package:flutter/material.dart';
import '../../../design/app_components.dart';
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
      body: SafeArea(
        child: storesAsync.isLoading
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
                    ? const EmptyState(
                        icon: Icons.storefront_outlined,
                        message: 'まだ店舗がありません。\nよく行くスーパーを登録しましょう。',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: stores.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PageBanner(
                                eyebrow: shopping ? '買い物の準備' : 'いつものお店',
                                title: shopping ? '今日はどこで買う？' : '売り場を、わが家の地図に。',
                                description: shopping
                                    ? 'お店を選んで、今日の買い物リストを作りましょう。'
                                    : '${stores.length}店舗のマップを家族で共有しています。',
                                icon: Icons.storefront_outlined,
                              ),
                            );
                          }
                          final store = stores[index - 1];
                          return Card(
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8EFE3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.storefront_outlined,
                                  color: Color(0xFF246653),
                                ),
                              ),
                              title: Text(
                                store.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: Text(
                                shopping ? 'この店で買うものを選ぶ' : '店内マップと売り場を確認',
                              ),
                              trailing: IconButton(
                                tooltip: '店内マップを編集',
                                onPressed: () => context
                                    .push('/stores/${store.id}/map/edit'),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              onTap: () => context.push(
                                '/stores/${store.id}/${shopping ? 'select' : 'map'}',
                              ),
                            ),
                          );
                        },
                      ),
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
