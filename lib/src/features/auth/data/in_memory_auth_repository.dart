import 'dart:async';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  static const _localUser = AppUser(
    uid: 'local-user',
    displayName: 'あなた',
    isAnonymous: true,
  );

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser = _localUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> watchUser() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signIn() async {
    _currentUser ??= _localUser;
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}
