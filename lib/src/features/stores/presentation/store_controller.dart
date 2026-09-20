import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/store.dart';

final storesProvider = NotifierProvider<StoreController, List<Store>>(
  StoreController.new,
);

class StoreController extends Notifier<List<Store>> {
  static const _uuid = Uuid();

  @override
  List<Store> build() => const [];

  void add(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    state = [
      ...state,
      Store(
        id: _uuid.v4(),
        householdId: 'local-household',
        name: trimmed,
        mapWidth: 12,
        mapHeight: 16,
      ),
    ];
  }

  void remove(String id) {
    state = state.where((store) => store.id != id).toList();
  }
}
