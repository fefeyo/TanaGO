import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;
  Future<AppUser>? _signInInFlight;

  @override
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Stream<AppUser?> watchUser() {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  Future<AppUser> signIn() {
    final current = currentUser;
    if (current != null) return Future.value(current);
    return _signInInFlight ??= _signInAnonymously();
  }

  Future<AppUser> _signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      final user = _mapUser(credential.user);
      if (user == null) throw StateError('認証情報を取得できませんでした');
      return user;
    } finally {
      _signInInFlight = null;
    }
  }

  @override
  Future<void> signOut() async {
    // A delayed anonymous sign-in must not undo an explicit sign-out.
    try {
      await _signInInFlight;
    } finally {
      await _auth.signOut();
    }
  }

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
