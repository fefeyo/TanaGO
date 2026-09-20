import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/stores/presentation/store_controller.dart';

void main() {
  test('creates stores in the selected household', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(storesProvider('household-a').notifier).add('スーパーA');

    final store = container.read(storesProvider('household-a')).single;
    expect(store.name, 'スーパーA');
    expect(store.householdId, 'household-a');
  });

  test('keeps stores isolated per household', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(storesProvider('household-a').notifier).add('スーパーA');
    container.read(storesProvider('household-b').notifier).add('スーパーB');

    expect(
      container.read(storesProvider('household-a')).single.name,
      'スーパーA',
    );
    expect(
      container.read(storesProvider('household-b')).single.name,
      'スーパーB',
    );
  });
}
