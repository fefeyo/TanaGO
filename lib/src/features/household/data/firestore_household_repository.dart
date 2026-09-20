import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/household.dart';
import '../domain/household_repository.dart';

class FirestoreHouseholdRepository implements HouseholdRepository {
  FirestoreHouseholdRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<Household?> watchCurrentHousehold(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().asyncMap(
      (user) async {
        final householdId = user.data()?['householdId'] as String?;
        if (householdId == null) return null;

        final household =
            await _firestore.collection('households').doc(householdId).get();
        if (!household.exists) return null;
        return _householdFromDocument(household);
      },
    );
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
    final inviteCode = _inviteCode(householdRef.id);
    final batch = _firestore.batch();

    batch.set(householdRef, {
      'name': name,
      'createdByUid': ownerUid,
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(householdRef.collection('members').doc(ownerUid), {
      'displayName': ownerDisplayName,
      'role': HouseholdRole.owner.name,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection('users').doc(ownerUid), {
      'householdId': householdRef.id,
    }, SetOptions(merge: true));

    await batch.commit();
    return Household(
      id: householdRef.id,
      name: name,
      createdByUid: ownerUid,
    );
  }

  @override
  Future<Household> joinHousehold({
    required String inviteCode,
    required String uid,
    required String displayName,
  }) async {
    final normalized = inviteCode.trim().toUpperCase();
    final matches = await _firestore
        .collection('households')
        .where('inviteCode', isEqualTo: normalized)
        .limit(1)
        .get();

    if (matches.docs.isEmpty) {
      throw StateError('招待コードが見つかりません');
    }

    final householdRef = matches.docs.single.reference;
    final batch = _firestore.batch();
    batch.set(householdRef.collection('members').doc(uid), {
      'displayName': displayName,
      'role': HouseholdRole.member.name,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection('users').doc(uid), {
      'householdId': householdRef.id,
    }, SetOptions(merge: true));
    await batch.commit();

    return _householdFromDocument(matches.docs.single);
  }

  @override
  Future<String> getInviteCode(String householdId) async {
    final household =
        await _firestore.collection('households').doc(householdId).get();
    final code = household.data()?['inviteCode'] as String?;
    if (code == null) {
      throw StateError('招待コードがありません');
    }
    return code;
  }

  Household _householdFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return Household(
      id: document.id,
      name: data['name'] as String? ?? '',
      createdByUid: data['createdByUid'] as String? ?? '',
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

  String _inviteCode(String householdId) {
    final compact = householdId.replaceAll('-', '').toUpperCase();
    return 'TANA-${compact.substring(0, 4)}';
  }
}
