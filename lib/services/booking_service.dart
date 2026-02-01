import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing bookings with atomic availability updates
/// Prevents double-booking through Firestore transactions
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generates all dates between startDate and endDate (inclusive)
  /// Returns dates in yyyy-MM-dd format
  /// 
  /// Example:
  /// generateDateRange('2026-02-01', '2026-02-03') 
  /// → ['2026-02-01', '2026-02-02', '2026-02-03']
  List<String> generateDateRange(String startDateStr, String endDateStr) {
    final startDate = DateTime.parse(startDateStr);
    final endDate = DateTime.parse(endDateStr);

    if (endDate.isBefore(startDate)) {
      throw ArgumentError('End date must be after or equal to start date');
    }

    final List<String> dates = [];
    DateTime current = startDate;

    // Generate all dates in the range (inclusive)
    while (!current.isAfter(endDate)) {
      // Format as yyyy-MM-dd
      final dateStr = current.toIso8601String().split('T')[0];
      dates.add(dateStr);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Atomically approves a booking and blocks the requested dates
  /// 
  /// This function uses a Firestore transaction to ensure:
  /// 1. All requested dates are available in the vehicle
  /// 2. If available, those dates are removed from availability
  /// 3. Booking status is updated to APPROVED
  /// 4. Everything happens atomically (no race conditions)
  /// 
  /// Returns:
  /// - true: Booking approved successfully
  /// - false: Booking failed (partial availability or concurrent conflict)
  /// 
  /// Throws:
  /// - Exception with meaningful error message on failure
  Future<bool> approveBookingWithAvailabilityBlock(String bookingId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to approve bookings');
    }

    try {
      // Run atomic transaction
      final result = await _firestore.runTransaction<bool>(
        (transaction) async {
          // Step 1: Read booking document
          final bookingRef = _firestore.collection('bookings').doc(bookingId);
          final bookingSnapshot = await transaction.get(bookingRef);

          if (!bookingSnapshot.exists) {
            throw Exception('Booking not found');
          }

          final bookingData = bookingSnapshot.data()!;
          
          // Validate booking status
          final currentStatus = (bookingData['status'] as String?)?.trim().toLowerCase();
          if (currentStatus == 'approved') {
            throw Exception('Booking is already approved');
          }
          if (currentStatus == 'cancelled' || currentStatus == 'canceled') {
            throw Exception('Cannot approve a cancelled booking');
          }

          // Extract vehicle ID and date range
          final vehicleId = bookingData['vehicle_id'] as String?;
          if (vehicleId == null || vehicleId.isEmpty) {
            throw Exception('Booking does not have a valid vehicle ID');
          }

          // Get start and end dates
          String startDateStr;
          String endDateStr;

          // Check if dates are stored as strings (yyyy-MM-dd) or Timestamps
          if (bookingData['startDate'] is String) {
            startDateStr = bookingData['startDate'] as String;
            endDateStr = bookingData['endDate'] as String;
          } else {
            // Fallback: convert from Timestamp fields
            final startTime = bookingData['start_time'] as Timestamp?;
            final endTime = bookingData['end_time'] as Timestamp?;
            
            if (startTime == null || endTime == null) {
              throw Exception('Booking does not have valid dates');
            }

            final startDate = startTime.toDate();
            final endDate = endTime.toDate();
            startDateStr = startDate.toIso8601String().split('T')[0];
            endDateStr = endDate.toIso8601String().split('T')[0];
          }

          // Step 2: Generate all dates in the booking range
          final requestedDates = generateDateRange(startDateStr, endDateStr);
          
          print('📅 Requested dates for booking $bookingId: $requestedDates');

          // Step 3: Read vehicle document
          final vehicleRef = _firestore.collection('vehicles').doc(vehicleId);
          final vehicleSnapshot = await transaction.get(vehicleRef);

          if (!vehicleSnapshot.exists) {
            throw Exception('Vehicle not found');
          }

          final vehicleData = vehicleSnapshot.data()!;
          final availabilityRaw = vehicleData['availability'];
          
          // Handle availability as List<dynamic> from Firestore
          final List<String> currentAvailability;
          if (availabilityRaw is List) {
            currentAvailability = availabilityRaw.cast<String>();
          } else {
            throw Exception('Vehicle does not have a valid availability array');
          }

          print('📋 Current vehicle availability: $currentAvailability');

          // Step 4: Check if ALL requested dates are available
          // requestedDates ⊆ currentAvailability
          final unavailableDates = <String>[];
          for (final date in requestedDates) {
            if (!currentAvailability.contains(date)) {
              unavailableDates.add(date);
            }
          }

          if (unavailableDates.isNotEmpty) {
            print('❌ Unavailable dates: $unavailableDates');
            throw Exception(
              'Cannot approve booking: Dates not available: ${unavailableDates.join(", ")}',
            );
          }

          // Step 5: Remove booked dates from availability
          final updatedAvailability = currentAvailability
              .where((date) => !requestedDates.contains(date))
              .toList();

          print('✅ All dates available. Removing from availability...');
          print('🔄 Updated availability: $updatedAvailability');

          // Step 6: Update vehicle availability (atomically)
          transaction.update(vehicleRef, {
            'availability': updatedAvailability,
          });

          // Step 7: Update booking status to APPROVED (atomically)
          transaction.update(bookingRef, {
            'status': 'APPROVED',
            'approved_at': FieldValue.serverTimestamp(),
            'approved_by': currentUser.uid,
          });

          print('✅ Booking $bookingId approved successfully');
          return true;
        },
        timeout: const Duration(seconds: 10),
      );

      return result;
    } on FirebaseException catch (e) {
      print('❌ Firebase error during approval: ${e.code} - ${e.message}');
      
      // Handle specific transaction errors
      if (e.code == 'aborted') {
        throw Exception('Approval failed: Another operation is in progress. Please try again.');
      } else if (e.code == 'deadline-exceeded') {
        throw Exception('Approval timeout: Please check your connection and try again.');
      }
      
      rethrow;
    } catch (e) {
      print('❌ Error during booking approval: $e');
      rethrow;
    }
  }

  /// Rejects a booking without affecting vehicle availability
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> rejectBooking(String bookingId, {String? reason}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to reject bookings');
    }

    try {
      final updateData = {
        'status': 'REJECTED',
        'rejected_at': FieldValue.serverTimestamp(),
        'rejected_by': currentUser.uid,
      };

      if (reason != null && reason.isNotEmpty) {
        updateData['rejection_reason'] = reason;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);
      
      print('✅ Booking $bookingId rejected successfully');
      return true;
    } catch (e) {
      print('❌ Error rejecting booking: $e');
      rethrow;
    }
  }

  /// Cancels a booking and restores availability if it was approved
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> cancelBooking(String bookingId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to cancel bookings');
    }

    try {
      final result = await _firestore.runTransaction<bool>(
        (transaction) async {
          // Read booking
          final bookingRef = _firestore.collection('bookings').doc(bookingId);
          final bookingSnapshot = await transaction.get(bookingRef);

          if (!bookingSnapshot.exists) {
            throw Exception('Booking not found');
          }

          final bookingData = bookingSnapshot.data()!;
          final currentStatus = (bookingData['status'] as String?)?.trim().toUpperCase();
          
          // Update booking status to CANCELLED
          transaction.update(bookingRef, {
            'status': 'CANCELLED',
            'cancelled_at': FieldValue.serverTimestamp(),
            'cancelled_by': currentUser.uid,
          });

          // If booking was APPROVED, restore availability
          if (currentStatus == 'APPROVED') {
            final vehicleId = bookingData['vehicle_id'] as String?;
            if (vehicleId != null && vehicleId.isNotEmpty) {
              // Get date range
              String startDateStr;
              String endDateStr;

              if (bookingData['startDate'] is String) {
                startDateStr = bookingData['startDate'] as String;
                endDateStr = bookingData['endDate'] as String;
              } else {
                final startTime = bookingData['start_time'] as Timestamp?;
                final endTime = bookingData['end_time'] as Timestamp?;
                
                if (startTime != null && endTime != null) {
                  startDateStr = startTime.toDate().toIso8601String().split('T')[0];
                  endDateStr = endTime.toDate().toIso8601String().split('T')[0];
                } else {
                  // Can't restore if dates are missing
                  print('⚠️ Cannot restore availability: missing dates');
                  return true;
                }
              }

              final datesToRestore = generateDateRange(startDateStr, endDateStr);
              
              // Read vehicle and restore dates
              final vehicleRef = _firestore.collection('vehicles').doc(vehicleId);
              final vehicleSnapshot = await transaction.get(vehicleRef);

              if (vehicleSnapshot.exists) {
                final vehicleData = vehicleSnapshot.data()!;
                final availabilityRaw = vehicleData['availability'];
                
                final List<String> currentAvailability;
                if (availabilityRaw is List) {
                  currentAvailability = availabilityRaw.cast<String>();
                } else {
                  currentAvailability = [];
                }

                // Add back the cancelled dates (avoid duplicates)
                final restoredAvailability = {...currentAvailability, ...datesToRestore}.toList()
                  ..sort(); // Sort chronologically

                transaction.update(vehicleRef, {
                  'availability': restoredAvailability,
                });

                print('✅ Availability restored for cancelled booking: $datesToRestore');
              }
            }
          }

          return true;
        },
        timeout: const Duration(seconds: 10),
      );

      return result;
    } catch (e) {
      print('❌ Error cancelling booking: $e');
      rethrow;
    }
  }
}
