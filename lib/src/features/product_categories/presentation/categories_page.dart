import 'package:flutter/material.dart';
import '../../../design/app_components.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../household/presentation/household_controller.dart';
import 'category_controller.dart';
import 'category_dialog.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hid = ref.watch(householdProvider).requireValue!.id;
    return Scaffold(
      appBar: AppBar(title: const Text('カテゴリ')),
      body: ref.watch(categoriesProvider(hid)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(categoriesProvider(hid)),
                child: const Text('再読み込み'),
              ),
            ),
            data: (categories) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const PageBanner(
                  eyebrow: 'わが家の整理整頓',
                  title: '売り場とリストをつなぐ。',
                  icon: Icons.category_outlined,
                  description: 'カテゴリは家族で共有され、商品と店舗の棚に設定できます。',
                ),
                const SizedBox(height: 20),
                for (final category in categories)
                  Card(
                    child: ListTile(
                      leading: CategorySymbol(categoryId: category.id),
                      title: Text(category.name),
                      trailing: category.id.startsWith('custom_')
                          ? const Icon(Icons.edit_outlined)
                          : null,
                      onTap: category.id.startsWith('custom_')
                          ? () => showCategoryDialog(
                                context,
                                hid,
                                category: category,
                              )
                          : null,
                    ),
                  ),
                const SizedBox(height: 90),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryDialog(context, hid),
        icon: const Icon(Icons.add),
        label: const Text('カテゴリを作成'),
      ),
    );
  }
}
