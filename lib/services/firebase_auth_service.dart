import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  static String? adminEmail;
  static String? adminPassword;

  static void storeAdminCredentials({
    required String email,
    required String password,
  }) {
    adminEmail = email;
    adminPassword = password;
  }

  static Future<void> restoreAdminSession() async {
    if (adminEmail == null || adminPassword == null) return;
    final currentEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentEmail?.toLowerCase() == adminEmail?.toLowerCase()) return;
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: adminEmail!,
      password: adminPassword!,
    );
  }

  static String _authEmailFromAdmission(String admissionNumber) {
    return '${admissionNumber.trim().toLowerCase()}@voters.evote.app';
  }

  static Future<String> _emailForAdmission(String admissionNumber) async {
    final trimmed = admissionNumber.trim().toLowerCase();
    if (trimmed.contains('@')) return trimmed;

    final authEmail = _authEmailFromAdmission(trimmed);
    final voterSnapshot = await FirebaseFirestore.instance.collection('voters').doc(trimmed).get();
    final configuredEmail = voterSnapshot.data()?['email']?.toString().trim();
    if (configuredEmail != null && configuredEmail.isNotEmpty) {
      return configuredEmail;
    }
    return authEmail;
  }

  static Future<String?> getCurrentRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final tokenResult = await user.getIdTokenResult(true);
    final claims = tokenResult.claims;
    final rawRole = claims?['role'];
    if (rawRole is String) return rawRole.toLowerCase();

    final rawAdmin = claims?['isAdmin'];
    if (rawAdmin is bool && rawAdmin) return 'admin';

    return null;
  }

  static Future<void> sendPasswordResetEmailByAdmissionNumber({
    required String admissionNumber,
  }) async {
    final trimmed = admissionNumber.trim();
    final configuredEmail = await _emailForAdmission(trimmed);
    final targetEmail = configuredEmail.trim().isNotEmpty
        ? configuredEmail.toLowerCase()
        : _authEmailFromAdmission(trimmed);

    await FirebaseAuth.instance.sendPasswordResetEmail(email: targetEmail);
  }

  static Future<void> updatePassword(String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.updatePassword(newPassword);
  }
}

