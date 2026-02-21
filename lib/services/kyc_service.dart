import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
      "verification_status": "pending",
      "created_at": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateVerificationStatus(String status) async {
    final normalizedStatus = status.trim().toLowerCase();

    // Update kyc_requests collection
    await _firestore.collection('kyc_requests').doc(uid).set({
      'verification_status': normalizedStatus,
    }, SetOptions(merge: true));

    // Only approved KYC should mark user as verified.
    if (normalizedStatus == 'approved') {
      await _firestore.collection('users').doc(uid).set({
        'verification_status': 'verified',
        'is_verified': true,
        'verified_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> sendEmailVerification(String email) async {
    final user = FirebaseAuth.instance.currentUser;
    // print("🔍 sendEmailVerification called with email: $email");
    // print("🔍 Current user: ${user?.uid}");
    // print("🔍 Current user email: ${user?.email}");
    // print("🔍 Email verified status: ${user?.emailVerified}");

    if (user != null) {
      try {
        // Update user's email if it differs from the form input
        if (user.email != email) {
          //print("📧 Email mismatch detected. Updating to: $email");
          await user.verifyBeforeUpdateEmail(email);
          //print("✅ Email verification link sent to: $email");
        } else {
          //print("📧 Email matches current user email");
          // Send verification email if not already verified
          if (!user.emailVerified) {
            //print("📧 Sending verification email to: $email");
            await user.sendEmailVerification();
           // print("✅ Verification email sent successfully");
          } else {
            //print("⚠️ Email already verified");
          }
        }
      } catch (e) {
        //print("❌ Error sending email verification: $e");
        rethrow;
      }
    } else {
      //print("❌ No authenticated user found");
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
    
    // print("📱 sendPhoneOtp called with phone number: $phoneNumber");
    // print("📱 Current user: ${FirebaseAuth.instance.currentUser?.uid}");

    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        //print("✅ Phone verification completed automatically");
        if (!completer.isCompleted) completer.complete(null);
        await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        //print("❌ Phone verification failed: ${e.code} - ${e.message}");
        //print("❌ Error details: $e");
        if (!completer.isCompleted) completer.complete(null);
      },
      codeSent: (verificationId, resendToken) {
        //print("✅ OTP code sent successfully");
        //print("✅ Verification ID: $verificationId");
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        //print("⏱️ Code auto-retrieval timeout. Verification ID: $verificationId");
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

  /// Uploads selfie image to Firebase Storage under kyc/{userId}/selfie.jpg
  /// Returns the download URL of the uploaded selfie
  Future<String> uploadSelfie(File file) async {
    //print("Uploading selfie for user $uid");
    final ref = _storage.ref().child("kyc/$uid/selfie.jpg");
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    //print("Selfie uploaded successfully: $url");
    return url;
  }

  /// Gets the device ID (platform-specific identifier)
  /// Returns device identifier without hashing
  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown';

    if (Platform.isAndroid) {
      // Get Android device ID
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id; // Android ID (unique per device)
      //print("Android Device ID: $deviceId");
    } else if (Platform.isIOS) {
      // Get iOS device ID
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'unknown'; // iOS Vendor ID
      //print("iOS Device ID: $deviceId");
    }

    return deviceId;
  }

  /// Saves biometric verification status and device ID to Firestore
  /// Called after successful biometric authentication
  Future<void> saveBiometricVerification(String deviceId) async {
    //print("Saving biometric verification for user $uid with device $deviceId");
    await _firestore.collection("kyc_requests").doc(uid).set({
      "biometric_verified": true,
      "device_id": deviceId,
      "biometric_verified_at": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    //print("Biometric verification saved successfully");
  }

  /// Saves selfie URL to Firestore kyc_requests collection
  Future<void> saveSelfieUrl(String selfieUrl) async {
    //print("Saving selfie URL for user $uid");
    await _firestore.collection("kyc_requests").doc(uid).set({
      "selfie_url": selfieUrl,
      "selfie_uploaded_at": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    //print("Selfie URL saved successfully");
  }
}
