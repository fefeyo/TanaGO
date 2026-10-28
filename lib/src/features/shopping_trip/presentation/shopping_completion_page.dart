import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../design/app_components.dart';
import '../../../design/app_palette.dart';
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
  final _purchaseId = const Uuid().v4();
  Set<String>? _purchaseTargets;
  List<PurchaseRecord> _records = [];
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
                child: _completed != null
                    ? PurchaseCelebration(count: shown.length)
                    : PageBanner(
                        eyebrow: '最後に購入内容を確認',
                        icon: Icons.shopping_bag_outlined,
                        title: 'チェックした${checked.length}点を購入済みにします',
                        description:
                            '買っていないものはチェックを外してください。チェックした商品だけ登録一覧から消えます。',
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
                                subtitle: item.details.isEmpty
                                    ? null
                                    : Text(item.details),
                                secondary:
                                    CategorySymbol(categoryId: item.categoryId),
                                value: trip.checked.contains(item.id),
                                onChanged: _saving ||
                                        _purchaseTargets != null ||
                                        !asyncItems.hasValue
                                    ? null
                                    : (value) => ref
                                        .read(
                                          shoppingTripProvider(key).notifier,
                                        )
                                        .check(item.id, value ?? false),
                              )
                            : ListTile(
                                title: Text(item.name),
                                subtitle: item.details.isEmpty
                                    ? null
                                    : Text(item.details),
                                leading:
                                    CategorySymbol(categoryId: item.categoryId),
                                trailing: const Icon(
                                  Icons.check_circle,
                                  color: AppPalette.forest,
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
              if (_completed != null && _records.isNotEmpty)
                TextButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() {
                            _saving = true;
                            _error = null;
                          });
                          try {
                            await ref
                                .read(shoppingListControllerProvider(hid))
                                .undoPurchase(_records);
                            if (!context.mounted) return;
                            context.go('/');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('購入完了を取り消し、買いたいものに戻しました'),
                                margin: EdgeInsets.fromLTRB(16, 0, 16, 88),
                              ),
                            );
                          } catch (_) {
                            if (mounted) {
                              setState(() {
                                _saving = false;
                                _error = '取り消しに失敗しました。もう一度お試しください。';
                              });
                            }
                          }
                        },
                  icon: const Icon(Icons.undo),
                  label: Text(_saving ? '取り消し中…' : '購入完了を取り消す'),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving
                        ? null
                        : _completed != null
                            ? () => context.go('/')
                            : _saving ||
                                    (checked.isEmpty &&
                                        _purchaseTargets == null) ||
                                    !asyncItems.hasValue
                                ? null
                                : () async {
                                    setState(() {
                                      _saving = true;
                                      _error = null;
                                    });
                                    try {
                                      _purchaseTargets ??=
                                          checked.map((i) => i.id).toSet();
                                      final records = await ref
                                          .read(
                                            shoppingListControllerProvider(
                                              hid,
                                            ),
                                          )
                                          .complete(
                                            _purchaseTargets!,
                                            purchaseId: _purchaseId,
                                          );
                                      if (!context.mounted) return;
                                      ref
                                          .read(
                                            shoppingTripProvider(key).notifier,
                                          )
                                          .reset();
                                      if (mounted) {
                                        setState(() {
                                          _records = records;
                                          _completed = records
                                              .map((r) => r.item)
                                              .toList();
                                          _saving = false;
                                        });
                                      }
                                    } catch (_) {
                                      if (mounted) {
                                        setState(() {
                                          _saving = false;
                                          _error =
                                              '購入の確定に失敗しました。もう一度確定すると、続きから処理します。';
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
