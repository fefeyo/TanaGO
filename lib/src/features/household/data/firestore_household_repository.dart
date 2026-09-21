import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../domain/household.dart';
import '../domain/household_repository.dart';

class FirestoreHouseholdRepository implements HouseholdRepository {
  FirestoreHouseholdRepository(this._firestore);

  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  @override
  Stream<Household?> watchCurrentHousehold(String uid) {
    late StreamController<Household?> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
        userSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
        householdSubscription;
    String? currentId;
    var generation = 0;
    controller = StreamController<Household?>(
      onListen: () {
        userSubscription =
            _firestore.collection('users').doc(uid).snapshots().listen(
          (user) async {
            final id = user.data()?['householdId'] as String?;
            if (id != null && id == currentId) return;
            currentId = id;
            final version = ++generation;
            await householdSubscription?.cancel();
            if (controller.isClosed || version != generation) return;
            if (id == null) {
              controller.add(null);
              return;
            }
            householdSubscription =
                _firestore.collection('households').doc(id).snapshots().listen(
              (document) {
                if (version != generation) return;
                controller.add(
                  document.exists ? _householdFromDocument(document) : null,
                );
              },
              onError: (Object error, StackTrace stack) {
                if (version == generation) controller.addError(error, stack);
              },
            );
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        generation++;
        await userSubscription?.cancel();
        await householdSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('members')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(_memberFromDocument).toList(),
        );
  }

  @override
  Future<Household> createHousehold({
    required String name,
    required String ownerUid,
    required String ownerDisplayName,
  }) async {
    final householdRef = _firestore.collection('households').doc();
    // 122 random bits, independent of the household id. Never enumerate households.
    final inviteCode = 'TANA-${_uuid.v4().replaceAll('-', '').toUpperCase()}';
    final inviteRef = _firestore.collection('householdInvites').doc(inviteCode);
    final userRef = _firestore.collection('users').doc(ownerUid);
    await _firestore.runTransaction((transaction) async {
      final user = await transaction.get(userRef);
      if (user.data()?['householdId'] != null) {
        throw StateError('すでに世帯に参加しています');
      }
      final invite = await transaction.get(inviteRef);
      if (invite.exists) throw StateError('招待コードを生成し直してください');
      transaction.set(householdRef, {
        'name': name,
        'createdByUid': ownerUid,
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(inviteRef, {'householdId': householdRef.id});
      transaction.set(householdRef.collection('members').doc(ownerUid), {
        'displayName': ownerDisplayName,
        'role': HouseholdRole.owner.name,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(
        userRef,
        {'householdId': householdRef.id},
        SetOptions(merge: true),
      );
    });
    return Household(id: householdRef.id, name: name, createdByUid: ownerUid);
  }

  @override
  Future<Household> joinHousehold({
    required String inviteCode,
    required String uid,
    required String displayName,
  }) async {
    final normalized = inviteCode.trim().toUpperCase();
    if (!RegExp(r'^TANA-[0-9A-F]{32}$').hasMatch(normalized)) {
      throw StateError('招待コードを確認してください');
    }
    final userRef = _firestore.collection('users').doc(uid);
    final householdId = await _firestore.runTransaction((transaction) async {
      final invite = await transaction
          .get(_firestore.collection('householdInvites').doc(normalized));
      final id = invite.data()?['householdId'] as String?;
      if (id == null) throw StateError('招待コードが見つかりません');
      final user = await transaction.get(userRef);
      final currentId = user.data()?['householdId'];
      if (currentId == id) {
        return id; // Preserve owner role and joinedAt on retries.
      }
      if (currentId != null) throw StateError('すでに別の世帯に参加しています');
      final memberRef = _firestore
          .collection('households')
          .doc(id)
          .collection('members')
          .doc(uid);
      transaction.set(memberRef, {
        'displayName': displayName,
        'role': HouseholdRole.member.name,
        'joinedAt': FieldValue.serverTimestamp(),
        'inviteCode': normalized,
      });
      transaction.set(userRef, {'householdId': id}, SetOptions(merge: true));
      return id;
    });
    // Only members can read the household; do this after the atomic join.
    final household =
        await _firestore.collection('households').doc(householdId).get();
    return _householdFromDocument(household);
  }

  @override
  Future<String> getInviteCode(String householdId) async {
    final household =
        await _firestore.collection('households').doc(householdId).get();
    final code = household.data()?['inviteCode'] as String?;
    if (code == null) throw StateError('招待コードがありません');
    return code;
  }

  Household _householdFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return Household(
      id: document.id,
      name: data['name'] as String,
      createdByUid: data['createdByUid'] as String,
    );
  }

  HouseholdMember _memberFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return HouseholdMember(
      uid: document.id,
      displayName: data['displayName'] as String? ?? '',
      role: data['role'] == HouseholdRole.owner.name
          ? HouseholdRole.owner
          : HouseholdRole.member,
    );
  }
}
