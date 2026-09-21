import 'dart:async';

import 'package:uuid/uuid.dart';

import '../domain/household.dart';
import '../domain/household_repository.dart';

class InMemoryHouseholdRepository implements HouseholdRepository {
  static const _uuid = Uuid();

  final _households = <String, Household>{};
  final _members = <String, List<HouseholdMember>>{};
  final _householdByUid = <String, String>{};
  final _inviteCodes = <String, String>{};
  final _currentHouseholdControllers = <String, StreamController<Household?>>{};
  final _memberControllers =
      <String, StreamController<List<HouseholdMember>>>{};

  @override
  Stream<Household?> watchCurrentHousehold(String uid) async* {
    yield _householdForUid(uid);
    yield* _currentHouseholdController(uid).stream;
  }

  @override
  Stream<List<HouseholdMember>> watchMembers(String householdId) async* {
    yield List.unmodifiable(_members[householdId] ?? const []);
    yield* _memberController(householdId).stream;
  }

  @override
  Future<Household> createHousehold({
    required String name,
    required String ownerUid,
    required String ownerDisplayName,
  }) async {
    if (_householdByUid.containsKey(ownerUid)) {
      throw StateError('すでに世帯に参加しています');
    }
    final id = _uuid.v4();
    final household = Household(id: id, name: name, createdByUid: ownerUid);
    _households[id] = household;
    _members[id] = [
      HouseholdMember(
        uid: ownerUid,
        displayName: ownerDisplayName,
        role: HouseholdRole.owner,
      ),
    ];
    _householdByUid[ownerUid] = id;
    _inviteCodes[id] = 'TANA-${_uuid.v4().replaceAll('-', '').toUpperCase()}';
    _emitHousehold(ownerUid);
    _emitMembers(id);
    return household;
  }

  @override
  Future<Household> joinHousehold({
    required String inviteCode,
    required String uid,
    required String displayName,
  }) async {
    final normalized = inviteCode.trim().toUpperCase();
    String? householdId;
    for (final entry in _inviteCodes.entries) {
      if (entry.value == normalized) {
        householdId = entry.key;
        break;
      }
    }
    if (householdId == null) {
      throw const HouseholdInviteException('招待コードが見つかりません');
    }
    final household = _households[householdId];
    if (household == null) {
      throw const HouseholdInviteException('世帯が見つかりません');
    }
    final currentId = _householdByUid[uid];
    if (currentId != null && currentId != householdId) {
      throw StateError('すでに別の世帯に参加しています');
    }
    final members = _members[householdId] ?? const <HouseholdMember>[];
    if (!members.any((member) => member.uid == uid)) {
      _members[householdId] = [
        ...members,
        HouseholdMember(
          uid: uid,
          displayName: displayName,
          role: HouseholdRole.member,
        ),
      ];
    }
    _householdByUid[uid] = householdId;
    _emitHousehold(uid);
    _emitMembers(householdId);
    return household;
  }

  @override
  Future<String> getInviteCode(String householdId) async {
    final code = _inviteCodes[householdId];
    if (code == null) {
      throw const HouseholdInviteException('招待コードがありません');
    }
    return code;
  }

  Household? _householdForUid(String uid) {
    final householdId = _householdByUid[uid];
    return householdId == null ? null : _households[householdId];
  }

  StreamController<Household?> _currentHouseholdController(String uid) {
    return _currentHouseholdControllers.putIfAbsent(
      uid,
      () => StreamController<Household?>.broadcast(),
    );
  }

  StreamController<List<HouseholdMember>> _memberController(
    String householdId,
  ) {
    return _memberControllers.putIfAbsent(
      householdId,
      () => StreamController<List<HouseholdMember>>.broadcast(),
    );
  }

  void _emitHousehold(String uid) {
    _currentHouseholdController(uid).add(_householdForUid(uid));
  }

  void _emitMembers(String householdId) {
    _memberController(householdId)
        .add(List.unmodifiable(_members[householdId] ?? const []));
  }
}

class HouseholdInviteException implements Exception {
  const HouseholdInviteException(this.message);
  final String message;
  @override
  String toString() => message;
}
