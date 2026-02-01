import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class KycService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  String? _verificationId;

  String get uid => _auth.currentUser!.uid;

  Future<String> uploadImage(File file, String name) async {
    print("Uploading $name for user $uid");
    final ref = _storage.ref().child("kyc/$uid/$name.jpg");
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> saveData(Map<String, dynamic> data) async {
    await _firestore.collection("kyc_requests").doc(uid).set({
      ...data,
      "user_id": uid,
      "status": "pending",
      "created_at": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateVerificationStatus(String status) async {
    // Update kyc_requests collection
    await _firestore.collection('kyc_requests').doc(uid).update({
      'verification_status': status,
      'verified_at': FieldValue.serverTimestamp(),
    });
    
    // Also update users collection to maintain consistency
    await _firestore.collection('users').doc(uid).update(
      {
        'verification_status': status,
        'verified_at': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> sendEmailVerification(String email) async {
    final user = FirebaseAuth.instance.currentUser;
    print("🔍 sendEmailVerification called with email: $email");
    print("🔍 Current user: ${user?.uid}");
    print("🔍 Current user email: ${user?.email}");
    print("🔍 Email verified status: ${user?.emailVerified}");

    if (user != null) {
      try {
        // Update user's email if it differs from the form input
        if (user.email != email) {
          print("📧 Email mismatch detected. Updating to: $email");
          await user.verifyBeforeUpdateEmail(email);
          print("✅ Email verification link sent to: $email");
        } else {
          print("📧 Email matches current user email");
          // Send verification email if not already verified
          if (!user.emailVerified) {
            print("📧 Sending verification email to: $email");
            await user.sendEmailVerification();
            print("✅ Verification email sent successfully");
          } else {
            print("⚠️ Email already verified");
          }
        }
      } catch (e) {
        print("❌ Error sending email verification: $e");
        rethrow;
      }
    } else {
      print("❌ No authenticated user found");
    }
  }

  Future<String> getVerificationStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return "unverified";

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    return (doc.data()?['verification_status'] ?? "unverified")
        .toString()
        .trim()
        .toLowerCase();
  }

  /// Sends phone OTP and returns the [verificationId] when the code is sent.
  /// Returns null if verification failed (e.g. invalid number).
  Future<String?> sendPhoneOtp(String phoneNumber) async {
    final completer = Completer<String?>();
    _verificationId = null;
    
    print("📱 sendPhoneOtp called with phone number: $phoneNumber");
    print("📱 Current user: ${FirebaseAuth.instance.currentUser?.uid}");

    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        print("✅ Phone verification completed automatically");
        if (!completer.isCompleted) completer.complete(null);
        await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("❌ Phone verification failed: ${e.code} - ${e.message}");
        print("❌ Error details: $e");
        if (!completer.isCompleted) completer.complete(null);
      },
      codeSent: (verificationId, resendToken) {
        print("✅ OTP code sent successfully");
        print("✅ Verification ID: $verificationId");
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        print("⏱️ Code auto-retrieval timeout. Verification ID: $verificationId");
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      timeout: const Duration(seconds: 60),
    );
    return completer.future;
  }

  Future<DocumentSnapshot> getKyc() async {
    return await _firestore.collection("kyc_requests").doc(uid).get();
  }
}
