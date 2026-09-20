import 'app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> watchUser();

  AppUser? get currentUser;

  Future<AppUser> signIn();

  Future<void> signOut();
}
