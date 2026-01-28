import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class KycService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  String get uid => _auth.currentUser!.uid;

  Future<String> uploadImage(File file, String name) async {
    print(  "Uploading $name for user $uid");
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
  await _firestore.collection('kyc').doc(uid).update({
    'verification_status': status,
    'verified_at': FieldValue.serverTimestamp(),
  });
}

Future<String> getVerificationStatus() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return "unverified";

  final doc = await FirebaseFirestore.instance
      .collection('owners')
      .doc(uid)
      .get();

  return (doc.data()?['verification_status'] ?? "unverified")
      .toString()
      .trim()
      .toLowerCase();
}

  Future<DocumentSnapshot> getKyc() async {
    return await _firestore.collection("kyc_requests").doc(uid).get();
  }
}
