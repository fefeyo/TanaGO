import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/stores/data/in_memory_store_repository.dart';
import 'package:tanago/src/features/stores/presentation/store_controller.dart';

ProviderContainer createContainer() {
  return ProviderContainer(
    overrides: [
      storeRepositoryProvider.overrideWithValue(InMemoryStoreRepository()),
    ],
  );
}

void main() {
  test('creates stores in the selected household', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    await container
        .read(storeControllerProvider('household-a'))
        .add('スーパーA');

    final repository = container.read(storeRepositoryProvider);
    final store = (await repository.getStores('household-a')).single;
    expect(store.name, 'スーパーA');
    expect(store.householdId, 'household-a');
  });

  test('keeps stores isolated per household', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    await container
        .read(storeControllerProvider('household-a'))
        .add('スーパーA');
    await container
        .read(storeControllerProvider('household-b'))
        .add('スーパーB');

    final repository = container.read(storeRepositoryProvider);
    expect((await repository.getStores('household-a')).single.name, 'スーパーA');
    expect((await repository.getStores('household-b')).single.name, 'スーパーB');
  });
}
