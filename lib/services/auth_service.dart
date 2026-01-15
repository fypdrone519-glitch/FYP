import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===================== EMAIL LOGIN =====================
  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw e.toString();
    }
  }

  // ===================== EMAIL SIGN UP =====================
  Future<User?> signUp(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw e.toString();
    }
  }

  // ===================== PHONE AUTH =====================
  Future<void> verifyPhone({
    required String phone,
    required Function(String verificationId) codeSent,
    required Function(String error) onError,
  }) async {
    try {
      print('🔥 Starting phone verification for: $phone');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Phone verification completed automatically');
          try {
            await _auth.signInWithCredential(credential);
            print('✅ Auto sign-in successful');
          } catch (e) {
            print('❌ Auto sign-in error: $e');
            onError(e.toString());
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Verification failed: ${e.code} - ${e.message}');
          onError('${e.code}: ${e.message ?? "Phone auth failed"}');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📱 Code sent! Verification ID: $verificationId');
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏱️ Auto-retrieval timeout for: $verificationId');
        },
      );
    } catch (e) {
      print('❌ Exception in verifyPhone: $e');
      onError(e.toString());
    }
  }

  Future<User?> verifyOTP(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  // ===================== LOGOUT =====================
  Future<void> logout() async {
    await _auth.signOut();
  }
}
