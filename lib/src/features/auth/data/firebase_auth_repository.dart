import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Stream<AppUser?> watchUser() {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  Future<AppUser> signIn() async {
    final current = _auth.currentUser;
    if (current != null) {
      return _mapUser(current)!;
    }

    final credential = await _auth.signInAnonymously();
    return _mapUser(credential.user)!;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'あなた',
      isAnonymous: user.isAnonymous,
    );
  }
}
