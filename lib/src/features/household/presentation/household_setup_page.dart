import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'household_controller.dart';

class HouseholdSetupPage extends ConsumerStatefulWidget {
  const HouseholdSetupPage({super.key});

  @override
  ConsumerState<HouseholdSetupPage> createState() => _HouseholdSetupPageState();
}

class _HouseholdSetupPageState extends ConsumerState<HouseholdSetupPage> {
  final _nameController = TextEditingController(text: 'わが家');
  final _inviteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Icon(
              Icons.shopping_basket_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'TanaGO',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '家族の「買ってきて」を、\n迷わず買えるリストに。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 48),
            Text('新しい家を作る', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: '世帯名',
                hintText: '例：わが家',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _createHousehold,
              icon: const Icon(Icons.home_outlined),
              label: const Text('この名前で始める'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('または'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            Text('招待コードで参加', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _inviteController,
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: '招待コード',
                hintText: 'TANA-7K2P',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _joinHousehold(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _joinHousehold,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('家に参加する'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createHousehold() async {
    await _submit(
      () => ref.read(householdControllerProvider).create(_nameController.text),
    );
  }

  Future<void> _joinHousehold() async {
    await _submit(
      () => ref.read(householdControllerProvider).join(_inviteController.text),
    );
  }

  Future<void> _submit(Future<void> Function() action) async {
    setState(() => _isSubmitting = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
