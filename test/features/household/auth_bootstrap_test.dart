import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/auth/domain/app_user.dart';
import 'package:tanago/src/features/auth/domain/auth_repository.dart';
import 'package:tanago/src/features/auth/presentation/auth_controller.dart';
import 'package:tanago/src/features/household/data/in_memory_household_repository.dart';
import 'package:tanago/src/features/household/presentation/household_controller.dart';

class ControlledRepository implements AuthRepository {
  final changes = StreamController<AppUser?>.broadcast();
  var pending = Completer<AppUser>();
  int signInCalls = 0;
  @override
  AppUser? currentUser;
  @override
  Stream<AppUser?> watchUser() async* {
    yield currentUser;
    yield* changes.stream;
  }

  @override
  Future<AppUser> signIn() async {
    signInCalls++;
    final user = await pending.future;
    setUser(user);
    return user;
  }

  void setUser(AppUser? user) {
    currentUser = user;
    changes.add(user);
  }

  @override
  Future<void> signOut() async {
    setUser(null);
  }
}

void main() {
  test(
      'bootstrap waits, follows uid changes and clears the household on sign-out',
      () async {
    final auth = ControlledRepository();
    final households = InMemoryHouseholdRepository();
    final first = await households.createHousehold(
      name: 'A',
      ownerUid: 'a',
      ownerDisplayName: 'A',
    );
    final second = await households.createHousehold(
      name: 'B',
      ownerUid: 'b',
      ownerDisplayName: 'B',
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        householdRepositoryProvider.overrideWithValue(households),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
    });
    final subscription = container.listen(householdProvider, (_, __) {});
    addTearDown(subscription.close);
    expect(container.read(householdProvider).isLoading, true);
    expect(auth.signInCalls, 1);
    auth.pending
        .complete(const AppUser(uid: 'a', displayName: 'A', isAnonymous: true));
    expect((await container.read(householdProvider.future))?.id, first.id);
    auth.setUser(const AppUser(uid: 'b', displayName: 'B', isAnonymous: true));
    await Future<void>.delayed(Duration.zero);
    expect((await container.read(householdProvider.future))?.id, second.id);
    await auth.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(householdProvider.future), isNull);
    expect(auth.signInCalls, 1);
  });

  test('bootstrap failures reach the household error state', () async {
    final auth = ControlledRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        householdRepositoryProvider
            .overrideWithValue(InMemoryHouseholdRepository()),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await auth.changes.close();
    });
    final subscription = container.listen(householdProvider, (_, __) {});
    addTearDown(subscription.close);
    final failure =
        expectLater(container.read(householdProvider.future), throwsStateError);
    auth.pending.completeError(StateError('offline'));
    await failure;
    auth.pending = Completer<AppUser>();
    container.invalidate(authBootstrapProvider);
    final retry = container.read(authBootstrapProvider.future);
    auth.pending.complete(
      const AppUser(uid: 'retry', displayName: 'Retry', isAnonymous: true),
    );
    await retry;
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(householdProvider.future), isNull);
    expect(auth.signInCalls, 2);
  });
}
