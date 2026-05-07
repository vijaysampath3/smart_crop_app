import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() {
    return _instance;
  }
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track the verification ID for OTP validation
  String? _verificationId;

  // Stream of auth state changes to detect login/logout globally
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // 1. Send OTP
  Future<void> sendOTP(
    String phoneNumber, {
    required Function() onCodeSentCallback,
    required Function(String error) onErrorCallback,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (rarely triggers, but good to have)
          await _auth.signInWithCredential(credential);
          await _checkAndCreateUser();
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("Verification Failed: \${e.message}");
          onErrorCallback(e.message ?? "Verification failed.");
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSentCallback();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onErrorCallback("Failed to send OTP: $e");
    }
  }

  // 2. Verify OTP
  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) return false;

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);
      await _checkAndCreateUser();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("OTP Verification Failed: \${e.message}");
      return false;
    } catch (e) {
      return false;
    }
  }

  // 3. User Data Storage inside Firestore
  Future<void> _checkAndCreateUser() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnap = await docRef.get();

    // Only create if user document does NOT exist
    if (!docSnap.exists) {
      await docRef.set({
        "phone": user.phoneNumber ?? "",
        "uid": user.uid,
        "createdAt": FieldValue.serverTimestamp(),
        "name": "",
        "location": "",
      });
      debugPrint("✅ New User Document Created");
    } else {
      debugPrint("🟢 Existing User Logged In");
    }
  }

  // 4. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
