import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../map_editor/domain/map_object.dart';
import '../../map_editor/domain/store_map_key.dart';
import '../../map_editor/presentation/map_editor_controller.dart';
import '../../shopping_list/domain/shopping_item.dart';
import '../../shopping_list/presentation/shopping_list_controller.dart';

final storeShoppingItemsProvider = Provider.autoDispose
    .family<AsyncValue<List<ShoppingItem>>, StoreMapKey>((ref, key) {
  final items = ref.watch(shoppingListProvider(key.householdId));
  final objects = ref.watch(mapEditorProvider(key));
  if (items.hasError) return AsyncError(items.error!, items.stackTrace!);
  if (objects.hasError) return AsyncError(objects.error!, objects.stackTrace!);
  if (!items.hasValue || !objects.hasValue) return const AsyncLoading();
  final categoryIds = objects.requireValue
      .where((o) => o.type == MapObjectType.shelf)
      .expand((o) => o.categoryIds)
      .toSet();
  return AsyncData(
    items.requireValue
        .where((i) => !i.isPurchased && categoryIds.contains(i.categoryId))
        .toList(),
  );
});

class ShoppingTrip {
  ShoppingTrip({
    Set<String> selected = const {},
    Set<String> checked = const {},
  })  : selected = Set.unmodifiable(selected),
        checked = Set.unmodifiable(checked.intersection(selected));
  final Set<String> selected;
  final Set<String> checked;
}

final shoppingTripProvider = StateNotifierProvider.family<
    ShoppingTripController,
    ShoppingTrip,
    StoreMapKey>((ref, key) => ShoppingTripController());

class ShoppingTripController extends StateNotifier<ShoppingTrip> {
  ShoppingTripController() : super(ShoppingTrip());
  void select(String id, bool value) {
    final selected = {...state.selected};
    value ? selected.add(id) : selected.remove(id);
    state = ShoppingTrip(selected: selected, checked: state.checked);
  }

  void check(String id, bool value) {
    if (!state.selected.contains(id)) return;
    final checked = {...state.checked};
    value ? checked.add(id) : checked.remove(id);
    state = ShoppingTrip(selected: state.selected, checked: checked);
  }

  void reset() => state = ShoppingTrip();
}
