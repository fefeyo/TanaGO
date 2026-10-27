import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../product_categories/presentation/category_controller.dart';
import '../domain/shopping_item.dart';
import 'shopping_list_controller.dart';

Future<void> showRecentPurchases(BuildContext context, String householdId) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.8,
        child: _RecentPurchases(householdId: householdId),
      ),
    );

class _RecentPurchases extends ConsumerStatefulWidget {
  const _RecentPurchases({required this.householdId});
  final String householdId;
  @override
  ConsumerState<_RecentPurchases> createState() => _RecentPurchasesState();
}

class _RecentPurchasesState extends ConsumerState<_RecentPurchases> {
  final _adding = <String>{};
  final _added = <String>{};
  String? _error;

  String _identity(ShoppingItem item) =>
      '${item.name.trim()}\u0000${item.categoryId}';

  Future<void> _add(ShoppingItem item) async {
    final identity = _identity(item);
    if (_adding.contains(identity) || _added.contains(identity)) return;
    setState(() {
      _adding.add(identity);
      _error = null;
    });
    try {
      await ref.read(shoppingListControllerProvider(widget.householdId)).add(
            item.name,
            categoryId: item.categoryId,
            autoClassify: false,
            quantity: item.quantity,
            memo: item.memo,
          );
      if (mounted) setState(() => _added.add(identity));
    } catch (_) {
      if (mounted) setState(() => _error = '登録できませんでした。もう一度お試しください。');
    } finally {
      if (mounted) setState(() => _adding.remove(identity));
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(recentPurchasesProvider(widget.householdId));
    final active = ref.watch(shoppingListProvider(widget.householdId));
    final registered = {
      ..._added,
      ...?active.valueOrNull?.where((i) => !i.isPurchased).map(_identity),
    };
    final categories =
        ref.watch(categoriesProvider(widget.householdId)).valueOrNull ?? [];
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '最近買ったもの',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '閉じる',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('いつもの商品を、＋で買いたいものに追加できます。'),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
          Expanded(
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: TextButton(
                  onPressed: () => ref
                      .invalidate(recentPurchasesProvider(widget.householdId)),
                  child: const Text('履歴を再読み込み'),
                ),
              ),
              data: (records) {
                final unique = <String, ShoppingItem>{};
                for (final record in records) {
                  unique.putIfAbsent(_identity(record.item), () => record.item);
                }
                if (unique.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'まだ購入履歴がありません。\n次の購入完了から、ここに商品が残ります。',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView(
                  children: [
                    for (final entry in unique.entries)
                      ListTile(
                        title: Text(entry.value.name),
                        subtitle: Text(
                          [
                            categoryName(categories, entry.value.categoryId),
                            entry.value.details,
                          ].where((s) => s.isNotEmpty).join(' · '),
                        ),
                        trailing: registered.contains(entry.key)
                            ? const Text('登録済み')
                            : IconButton(
                                tooltip: '${entry.value.name}をもう一度登録',
                                onPressed: _adding.contains(entry.key) ||
                                        !active.hasValue
                                    ? null
                                    : () => _add(entry.value),
                                icon: _adding.contains(entry.key)
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.add_circle_outline),
                              ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
