import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../product_categories/domain/product_category_classifier.dart';
import '../../product_categories/presentation/category_controller.dart';
import '../../product_categories/presentation/category_dialog.dart';
import '../domain/shopping_item.dart';
import 'shopping_list_controller.dart';

Future<void> showShoppingItemDialog(
  BuildContext context,
  String householdId, {
  ShoppingItem? item,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ShoppingItemDialog(householdId: householdId, item: item),
    );

class _ShoppingItemDialog extends ConsumerStatefulWidget {
  const _ShoppingItemDialog({required this.householdId, this.item});
  final String householdId;
  final ShoppingItem? item;
  @override
  ConsumerState<_ShoppingItemDialog> createState() =>
      _ShoppingItemDialogState();
}

class _ShoppingItemDialogState extends ConsumerState<_ShoppingItemDialog> {
  late final _name = TextEditingController(text: widget.item?.name);
  late String? _categoryId = widget.item?.categoryId;
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller =
          ref.read(shoppingListControllerProvider(widget.householdId));
      if (widget.item == null) {
        await controller.add(
          _name.text,
          categoryId: _categoryId,
          autoClassify: false,
        );
      } else {
        await controller.edit(
          widget.item!.id,
          name: _name.text,
          categoryId: _categoryId,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存できませんでした。もう一度お試しください。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncCategories = ref.watch(categoriesProvider(widget.householdId));
    final categories = asyncCategories.valueOrNull ?? [];
    final suggestion = const ProductCategoryClassifier().classify(_name.text);
    return AlertDialog(
      title: Text(widget.item == null ? '買いたいものを登録' : '買いたいものを編集'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                enabled: !_saving,
                autofocus: true,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: '商品名',
                  hintText: '例：牛乳',
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) => value == null || value.trim().isEmpty
                    ? '商品名を入力してください'
                    : null,
              ),
              const SizedBox(height: 12),
              if (asyncCategories.isLoading) const LinearProgressIndicator(),
              if (asyncCategories.hasError)
                TextButton(
                  onPressed: () =>
                      ref.invalidate(categoriesProvider(widget.householdId)),
                  child: const Text('カテゴリを再読み込み'),
                ),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'category-${_categoryId ?? ''}-${categories.length}',
                ),
                initialValue: categories.any((c) => c.id == _categoryId)
                    ? _categoryId
                    : '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'カテゴリ'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('未分類')),
                  for (final c in categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(
                          () => _categoryId = value == '' ? null : value,
                        ),
              ),
              if (suggestion != null &&
                  suggestion != _categoryId &&
                  categories.isNotEmpty)
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() => _categoryId = suggestion),
                  child: Text(
                    '候補：${categoryName(categories, suggestion)}を使う',
                  ),
                ),
              TextButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        final created = await showCategoryDialog(
                          context,
                          widget.householdId,
                        );
                        if (created != null && mounted) {
                          setState(() => _categoryId = created.id);
                        }
                      },
                icon: const Icon(Icons.add),
                label: const Text('カテゴリを作成'),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _saving || !asyncCategories.hasValue ? null : _save,
          child: Text(_saving ? '保存中…' : '保存'),
        ),
      ],
    );
  }
}
