import 'package:flutter/material.dart';

class StoreListPage extends StatelessWidget {
  const StoreListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('店舗を選ぶ')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '次の実装で、店舗登録と店内マップクリエイターを追加します。',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null,
        icon: Icon(Icons.add_business),
        label: Text('店舗を追加'),
      ),
    );
  }
}
