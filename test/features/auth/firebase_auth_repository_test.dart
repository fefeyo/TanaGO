import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/auth/data/firebase_auth_repository.dart';

class FakeUser extends Fake implements User {
  @override
  String get uid => 'anonymous-user';
  @override
  String? get displayName => null;
  @override
  bool get isAnonymous => true;
}

class FakeCredential extends Fake implements UserCredential {
  @override
  User get user => FakeUser();
}

class ControlledAuth extends Fake implements FirebaseAuth {
  final pending = <Completer<UserCredential>>[];
  int signOutCalls = 0;
  @override
  User? get currentUser => null;
  @override
  Future<UserCredential> signInAnonymously() {
    final completer = Completer<UserCredential>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

void main() {
  test('concurrent callers share one anonymous sign-in', () async {
    final auth = ControlledAuth();
    final repository = FirebaseAuthRepository(auth);
    final first = repository.signIn();
    final second = repository.signIn();
    expect(auth.pending, hasLength(1));
    auth.pending.single.complete(FakeCredential());
    expect((await first).uid, (await second).uid);
  });

  test('failed sign-in can be retried', () async {
    final auth = ControlledAuth();
    final repository = FirebaseAuthRepository(auth);
    final first = repository.signIn();
    final failure = expectLater(first, throwsStateError);
    auth.pending.single.completeError(StateError('offline'));
    await failure;
    final retry = repository.signIn();
    expect(auth.pending, hasLength(2));
    auth.pending.last.complete(FakeCredential());
    expect((await retry).uid, 'anonymous-user');
  });

  test('sign-out waits for an in-flight anonymous sign-in', () async {
    final auth = ControlledAuth();
    final repository = FirebaseAuthRepository(auth);
    final signingIn = repository.signIn();
    final signingOut = repository.signOut();
    expect(auth.signOutCalls, 0);
    auth.pending.single.complete(FakeCredential());
    await signingIn;
    await signingOut;
    expect(auth.signOutCalls, 1);
  });
}
