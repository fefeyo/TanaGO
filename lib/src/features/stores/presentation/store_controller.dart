import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/store.dart';

final storesProvider =
    NotifierProvider.family<StoreController, List<Store>, String>(
  StoreController.new,
);

class StoreController extends FamilyNotifier<List<Store>, String> {
  static const _uuid = Uuid();

  late final String householdId;

  @override
  List<Store> build(String arg) {
    householdId = arg;
    return const [];
  }

  void add(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    state = [
      ...state,
      Store(
        id: _uuid.v4(),
        householdId: householdId,
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
