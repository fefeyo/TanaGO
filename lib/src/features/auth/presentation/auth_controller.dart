import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

final authUserProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).watchUser(),
);

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
