import 'package:flutter/material.dart';
import '../../../design/app_components.dart';
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
    final shown = _completed ??
        (asyncItems.valueOrNull ?? [])
            .where((i) => trip.selected.contains(i.id))
            .toList();
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(_completed == null ? '購入内容の確認' : '購入完了')),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: PageBanner(
                  eyebrow: _completed == null ? '最後に購入内容を確認' : 'お買い物、おつかれさまでした',
                  icon: _completed == null
                      ? Icons.shopping_bag_outlined
                      : Icons.task_alt,
                  title: _completed == null
                      ? 'チェックした${checked.length}点を購入済みにします'
                      : '${shown.length}点の購入が完了しました',
                  description: _completed == null
                      ? '買っていないものはチェックを外してください。チェックした商品だけ登録一覧から消えます。'
                      : '購入した商品を登録一覧から削除しました。',
                ),
              ),
              if (asyncItems.isLoading && _completed == null)
                const LinearProgressIndicator(),
              if (asyncItems.hasError && _completed == null)
                const Text('購入内容を読み込めませんでした。マップに戻って再読み込みしてください。'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final item in shown)
                      Card(
                        child: _completed == null
                            ? CheckboxListTile(
                                key: ValueKey('confirm-${item.id}'),
                                title: Text(item.name),
                                secondary:
                                    CategorySymbol(categoryId: item.categoryId),
                                value: trip.checked.contains(item.id),
                                onChanged: _saving || !asyncItems.hasValue
                                    ? null
                                    : (value) => ref
                                        .read(
                                          shoppingTripProvider(key).notifier,
                                        )
                                        .check(item.id, value ?? false),
                              )
                            : ListTile(
                                title: Text(item.name),
                                leading:
                                    CategorySymbol(categoryId: item.categoryId),
                                trailing: const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF246653),
                                ),
                              ),
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
