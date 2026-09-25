import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product_category.dart';
import 'category_controller.dart';

Future<ProductCategory?> showCategoryDialog(
  BuildContext context,
  String householdId, {
  ProductCategory? category,
}) =>
    showDialog<ProductCategory>(
      context: context,
      builder: (_) =>
          _CategoryDialog(householdId: householdId, category: category),
    );

class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog({required this.householdId, this.category});
  final String householdId;
  final ProductCategory? category;
  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  late final _name = TextEditingController(text: widget.category?.name);
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final category = await saveCategory(
        ref.read(categoryRepositoryProvider),
        widget.householdId,
        _name.text,
        id: widget.category?.id,
      );
      if (mounted) Navigator.pop(context, category);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is StateError
              ? error.message.toString()
              : error is ArgumentError
                  ? 'カテゴリ名は1〜50文字で入力してください'
                  : '保存できませんでした。もう一度お試しください。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.category == null ? 'カテゴリを作成' : 'カテゴリ名を編集'),
        content: TextField(
          controller: _name,
          enabled: !_saving,
          autofocus: true,
          maxLength: 50,
          decoration: InputDecoration(labelText: 'カテゴリ名', errorText: _error),
          onSubmitted: (_) => _save(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中…' : '保存'),
          ),
        ],
      );
}
