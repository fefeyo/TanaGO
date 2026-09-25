import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../household/presentation/household_controller.dart';
import '../../map_editor/domain/store_map_key.dart';
import '../../shopping_list/domain/shopping_item.dart';
import '../../shopping_list/presentation/shopping_list_controller.dart';
import 'shopping_trip_controller.dart';

class ShoppingCompletionPage extends ConsumerStatefulWidget {
  const ShoppingCompletionPage({super.key, required this.storeId});
  final String storeId;
  @override
  ConsumerState<ShoppingCompletionPage> createState() =>
      _ShoppingCompletionPageState();
}

class _ShoppingCompletionPageState
    extends ConsumerState<ShoppingCompletionPage> {
  bool _saving = false;
  String? _error;
  List<ShoppingItem>? _completed;
  @override
  Widget build(BuildContext context) {
    final hid = ref.watch(householdProvider).requireValue!.id;
    final key = StoreMapKey(householdId: hid, storeId: widget.storeId);
    final trip = ref.watch(shoppingTripProvider(key));
    final asyncItems = ref.watch(storeShoppingItemsProvider(key));
    final checked = (asyncItems.valueOrNull ?? [])
        .where(
          (i) => trip.selected.contains(i.id) && trip.checked.contains(i.id),
        )
        .toList();
    final shown = _completed ?? checked;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(_completed == null ? '購入内容の確認' : '購入完了')),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      _completed == null
                          ? Icons.shopping_bag_outlined
                          : Icons.check_circle_outline,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _completed == null
                          ? 'チェックした${checked.length}点を購入済みにします'
                          : '${shown.length}点の購入が完了しました',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _completed == null
                          ? '確定すると登録一覧から消えます。未チェックの商品は残ります。'
                          : '購入した商品を登録一覧から削除しました。',
                    ),
                  ],
                ),
              ),
              if (asyncItems.isLoading && _completed == null)
                const LinearProgressIndicator(),
              if (asyncItems.hasError && _completed == null)
                const Text('購入内容を読み込めませんでした。マップに戻って再読み込みしてください。'),
              Expanded(
                child: ListView(
                  children: [
                    for (final item in shown)
                      ListTile(
                        title: Text(item.name),
                        leading: const Icon(Icons.check),
                      ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _completed != null
                        ? () => context.go('/')
                        : _saving || checked.isEmpty || !asyncItems.hasValue
                            ? null
                            : () async {
                                setState(() {
                                  _saving = true;
                                  _error = null;
                                });
                                try {
                                  await ref
                                      .read(
                                        shoppingListControllerProvider(
                                          hid,
                                        ),
                                      )
                                      .complete(checked.map((i) => i.id));
                                  if (!mounted) return;
                                  ref
                                      .read(
                                        shoppingTripProvider(key).notifier,
                                      )
                                      .reset();
                                  if (mounted) {
                                    setState(() {
                                      _completed = checked;
                                      _saving = false;
                                    });
                                  }
                                } catch (_) {
                                  if (mounted) {
                                    setState(() {
                                      _saving = false;
                                      _error =
                                          '購入の確定に失敗しました。残っている商品を再度確定してください。';
                                    });
                                  }
                                }
                              },
                    child: Text(
                      _completed != null
                          ? '登録一覧に戻る'
                          : _saving
                              ? '確定中…'
                              : '購入を確定する',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
