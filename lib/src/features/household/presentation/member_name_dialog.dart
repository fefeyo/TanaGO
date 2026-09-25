import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'household_controller.dart';

class MemberNameDialog extends ConsumerStatefulWidget {
  const MemberNameDialog({
    super.key,
    required this.householdId,
    required this.name,
  });
  final String householdId;
  final String name;
  @override
  ConsumerState<MemberNameDialog> createState() => _MemberNameDialogState();
}

class _MemberNameDialogState extends ConsumerState<MemberNameDialog> {
  late final _name =
      TextEditingController(text: widget.name == 'あなた' ? '' : widget.name);
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
      setState(() => _error = '名前を入力してください');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(householdControllerProvider)
          .updateMyName(widget.householdId, _name.text);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存できませんでした';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('あなたの名前'),
        content: TextField(
          controller: _name,
          enabled: !_saving,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(labelText: '名前', errorText: _error),
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
