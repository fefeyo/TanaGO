import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

// Establish the initial session once. Auth changes are observed separately so
// sign-out never leaves a household subscription attached to the previous uid.
final authBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.watch(authControllerProvider).ensureSignedIn();
});

final authUserProvider = StreamProvider<AppUser?>((ref) {
  final bootstrap = ref.watch(authBootstrapProvider);
  final repository = ref.watch(authRepositoryProvider);
  // Subscribe after bootstrap: the stream's initial event now represents the
  // established session, not a transient null emitted during sign-in.
  return bootstrap.when(
    skipLoadingOnRefresh: false,
    skipLoadingOnReload: false,
    data: (_) => repository.watchUser(),
    error: (error, stack) => Stream.error(error, stack),
    loading: () => const Stream.empty(),
  );
});

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);

class AuthController {
  AuthController(this._repository);

  final AuthRepository _repository;

  Future<AppUser> ensureSignedIn() async {
    return _repository.currentUser ?? _repository.signIn();
  }

  Future<void> signOut() => _repository.signOut();
}
