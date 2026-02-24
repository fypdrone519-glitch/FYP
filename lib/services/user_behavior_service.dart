import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserBehaviorService {
  UserBehaviorService._();

  static final UserBehaviorService instance = UserBehaviorService._();
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  Future<void> logVehicleView(String vehicleId) async {
    //print('calling Logging vehicle view for vehicle ID: $vehicleId');
    await _call('logVehicleView', vehicleId);
  }

  Future<void> logVehicleBooking(String vehicleId) async {
    await _call('logVehicleBooking', vehicleId);
  }

  Future<void> _call(String functionName, String vehicleId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || vehicleId.trim().isEmpty) {
      if (uid == null) {
        //print('⚠️ $functionName skipped: user is not authenticated');
      }
      if (vehicleId.trim().isEmpty) {
        //print('⚠️ $functionName skipped: vehicleId is empty');
      }
      return;
    }

    try {
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call({'vehicleId': vehicleId});
      // print(
      //   '✅ $functionName success for vehicleId=$vehicleId, '
      //   'response=${result.data}',
      // );
      await _computeRecommendations(uid);
    } on FirebaseFunctionsException catch (error) {
      print(
        '❌ $functionName failed: code=${error.code}, '
        'message=${error.message}, details=${error.details}',
      );
    } catch (error) {
      print('❌ $functionName failed: $error');
    }
  }

  Future<void> _computeRecommendations(String userId) async {
    try {
      final callable = _functions.httpsCallable('computeRecommendedCars');
      final result = await callable.call({'userId': userId});
      //print('✅ computeRecommendedCars success: response=${result.data}');
    } on FirebaseFunctionsException catch (error) {
      print(
        '❌ computeRecommendedCars failed: code=${error.code}, '
        'message=${error.message}, details=${error.details}',
      );
    } catch (error) {
      print('❌ computeRecommendedCars failed: $error');
    }
  }
}
