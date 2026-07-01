import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_auth_service.dart';

class UserSecurityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String _authEmailFromAdmission(String admissionNumber) {
    return '${admissionNumber.trim().toLowerCase()}@voters.evote.app';
  }

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  static Future<void> ensureCurrentUserRecordExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final userDoc = _userDoc(user.uid);
    final snapshot = await userDoc.get();
    if (snapshot.exists) return;

    final authEmail = user.email?.trim() ?? '';
    final admissionNumber = authEmail.contains('@') ? authEmail.split('@').first : authEmail;
    final voterSnapshot = await _firestore.collection('voters').doc(admissionNumber).get();

    final currentRole = await FirebaseAuthService.getCurrentRole();
    final role = currentRole ?? 'voter';

    final data = <String, dynamic>{
      'uid': user.uid,
      'email': authEmail,
      'authEmail': authEmail,
      'username': admissionNumber,
      'admissionNumber': admissionNumber,
      'displayName': user.displayName ?? '',
      'role': role,
      'isFirstLogin': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (voterSnapshot.exists) {
      final voterData = voterSnapshot.data()!;
      final voterEmail = voterData['email']?.toString().trim();
      data['displayName'] = voterData['fullName'] ?? data['displayName'];
      data['email'] = (voterEmail?.isNotEmpty == true) ? voterEmail : authEmail;
      data['authEmail'] = _authEmailFromAdmission(admissionNumber);
      data['username'] = voterData['username'] ?? admissionNumber;
      data['role'] = 'voter';
    }

    await userDoc.set(data, SetOptions(merge: true));
  }

  static Future<bool> isFirstLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userDoc = _userDoc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await ensureCurrentUserRecordExists();
      return true;
    }

    final data = snapshot.data();
    return data?['isFirstLogin'] == true;
  }

  static Future<void> setIsFirstLogin(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _userDoc(user.uid).set(
      {
        'isFirstLogin': value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> saveSecurityData({
    required String securityQuestion,
    required String securityAnswerHash,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    await _userDoc(user.uid).set(
      {
        'securityQuestion': securityQuestion,
        'securityAnswerHash': securityAnswerHash,
        'isFirstLogin': false,
        'securityUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> createUserRecordForVoter({
    required String uid,
    required String admissionNumber,
    required String fullName,
    required String email,
    required String authEmail,
  }) async {
    final userDoc = _userDoc(uid);
    final snapshot = await userDoc.get();
    if (snapshot.exists) return;

    await userDoc.set(
      {
        'uid': uid,
        'email': email.trim(),
        'authEmail': authEmail,
        'displayName': fullName.trim(),
        'fullName': fullName.trim(),
        'username': admissionNumber.trim(),
        'admissionNumber': admissionNumber.trim(),
        'role': 'voter',
        'isFirstLogin': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
