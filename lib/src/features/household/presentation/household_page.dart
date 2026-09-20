import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/household.dart';
import 'household_controller.dart';

class HouseholdPage extends ConsumerWidget {
  const HouseholdPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider).valueOrNull;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final members =
        ref.watch(householdMembersProvider(household.id)).valueOrNull ??
            const <HouseholdMember>[];

    return Scaffold(
      appBar: AppBar(title: const Text('わが家')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(household.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('${members.length}人で共有中'),
          const SizedBox(height: 24),
          Text('メンバー', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final member in members)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                child: Text(
                  member.displayName.isEmpty ? '?' : member.displayName[0],
                ),
              ),
              title: Text(member.displayName),
              subtitle: Text(
                member.role == HouseholdRole.owner ? 'オーナー' : 'メンバー',
              ),
            ),
          const SizedBox(height: 24),
          Text('家族を招待', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: ref
                .read(householdControllerProvider)
                .getInviteCode(household.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }
              final code = snapshot.data!;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.key_outlined),
                  title: Text(code),
                  subtitle: const Text('このコードを家族に共有してください'),
                  trailing: IconButton(
                    tooltip: 'コピー',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('招待コードをコピーしました')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
