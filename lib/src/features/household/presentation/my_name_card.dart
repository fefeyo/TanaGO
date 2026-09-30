import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/household.dart';
import 'household_controller.dart';
import 'member_name_dialog.dart';

class MyNameCard extends ConsumerWidget {
  const MyNameCard({
    super.key,
    required this.householdId,
    this.onlyWhenMissing = false,
  });
  final String householdId;
  final bool onlyWhenMissing;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authUserProvider).valueOrNull?.uid;
    final members =
        ref.watch(householdMembersProvider(householdId)).valueOrNull;
    final me = members?.where((member) => member.uid == uid).firstOrNull;
    if (me == null) return const SizedBox.shrink();
    final missing = !hasMemberName(me.displayName, uid: me.uid);
    if (onlyWhenMissing && !missing) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              missing ? '家族に表示する名前を設定しましょう' : 'あなたの名前：${me.displayName}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (missing)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('買いたいものの登録者名にも使います。'),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => MemberNameDialog(
                    householdId: householdId,
                    name: missing ? '' : me.displayName,
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: Text(missing ? '名前を設定' : '自分の名前を変更'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
