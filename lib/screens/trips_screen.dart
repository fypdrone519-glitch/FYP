import 'dart:io';

import 'package:car_listing_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/booking_service.dart';
import 'booking_details_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';

class TripsScreen extends StatefulWidget {
  /// If true, show trips as HOST (bookings where owner_id == current user).
  /// If false, show trips as RENTER (bookings where renter_id == current user).
  final bool viewAsHost;

  const TripsScreen({super.key, this.viewAsHost = false});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final bool _viewAsHost;
  bool _isCancelling = false;
  bool _isApproving = false; // Track approval in progress
  final Set<String> _startingTripIds = {};
  final Set<String> _endingTripIds = {};
  final ImagePicker _imagePicker = ImagePicker();
  final BookingService _bookingService =
      BookingService(); // Atomic booking service

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewAsHost = widget.viewAsHost;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Text(
                'Activity',
                style: TextStyle(
                  fontSize: screenHeight * 0.032,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            // Tab Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: TextStyle(
                    fontSize: screenHeight * 0.018,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [Tab(text: 'Upcoming'), Tab(text: 'History')],
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUpcomingTab(screenHeight, screenWidth),
                  _buildHistoryTab(screenHeight, screenWidth),
                ],
              ),
            ),
          ],
        ),
      ),
      // // Add a floating action button to trips_screen.dart for testing
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     final bookingService = BookingService();
      //     final count = await bookingService.autoCompleteExpiredBookings();
      //     ScaffoldMessenger.of(
      //       context,
      //     ).showSnackBar(SnackBar(content: Text('Completed $count bookings')));
      //   },
      //   child: const Icon(Icons.bug_report),
      // ),
    );
  }

  /// Base query for bookings depending on current role (renter/host)
  Query<Map<String, dynamic>>? _baseBookingsQuery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final uid = user.uid;
    final collection = FirebaseFirestore.instance.collection('bookings');

    if (_viewAsHost) {
      // Host view: bookings for vehicles owned by this user
      return collection.where('owner_id', isEqualTo: uid);
    } else {
      // Renter view: bookings made by this user
      return collection.where('renter_id', isEqualTo: uid);
    }
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isEndDay(DateTime end) {
    final today = _startOfToday();
    final endDay = DateTime(end.year, end.month, end.day);
    return endDay == today;
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _formatMonthHeader(DateTime date) =>
      '${_monthName(date.month)} ${date.year}';

  String _formatDateRangeShort(DateTime start, DateTime end) {
    // Matches your UI example style: "Oct. 5 - 8, 2023"
    final startMonth = _monthName(start.month).substring(0, 3);
    final endMonth = _monthName(end.month).substring(0, 3);
    final startMonthLabel = '$startMonth.';
    final endMonthLabel = '$endMonth.';

    if (start.year == end.year && start.month == end.month) {
      return '$startMonthLabel ${start.day} - ${end.day}, ${start.year}';
    }
    if (start.year == end.year) {
      return '$startMonthLabel ${start.day} - $endMonthLabel ${end.day}, ${start.year}';
    }
    return '$startMonthLabel ${start.day}, ${start.year} - $endMonthLabel ${end.day}, ${end.year}';
  }

  String _formatHistorySectionRange(DateTime start, DateTime end) {
    // Matches your UI example style: "October 5 - 30, 2023"
    final month = _monthName(start.month);
    if (start.year == end.year && start.month == end.month) {
      return '$month ${start.day} - ${end.day}, ${start.year}';
    }
    return '${_formatMonthHeader(start)} - ${_formatMonthHeader(end)}';
  }

  Future<Map<String, dynamic>?> _loadVehicle(String vehicleId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(vehicleId)
              .get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  String _statusLabelForBooking(Map<String, dynamic> booking) {
    final raw = (booking['status'] as String?)?.trim().toLowerCase();
    if (raw == 'cancelled' || raw == 'canceled') return 'Cancelled';
    if (raw == 'approved') return 'Approved';
    if (raw == 'rejected') return 'Rejected';
    if (raw == 'completed') return 'Completed';
    if (raw == 'started') return 'Trip Started';
    if (raw == 'confirmed') return 'Confirmed';
    if (raw == 'pending') return 'Pending';
    if (raw == 'waiting for the approval' || raw == 'waiting') {
      return 'Waiting for the approval';
    }
    // Default: show as completed in history UI if unknown
    return 'Completed';
  }

  bool _isCancelled(Map<String, dynamic> booking) {
    final raw = (booking['status'] as String?)?.trim().toLowerCase();
    return raw == 'cancelled' || raw == 'canceled';
  }

  bool _isCompleted(Map<String, dynamic> booking) {
    final raw = (booking['status'] as String?)?.trim().toLowerCase();
    return raw == 'completed';
  }

  bool _isEnded(Map<String, dynamic> booking) {
    final raw = (booking['status'] as String?)?.trim().toLowerCase();
    return raw == 'ended';
  }
  bool _isWaitingForApproval(Map<String, dynamic> booking) {
    final raw = (booking['status'] as String?)?.trim().toLowerCase();
    return raw == 'waiting for the approval' ||
        raw == 'waiting' ||
        raw == 'pending'; // New PENDING status
  }

  bool _isApproved(Map<String, dynamic> booking) {
    final raw = (booking['status'] as String?)?.trim().toLowerCase();
    return raw == 'approved';
  }

  bool _isTripStarted(Map<String, dynamic> booking) {
    final raw = (booking['status'] as String?)?.trim().toLowerCase();
    return raw == 'started' || booking['trip_started_at'] != null;
  }

  DateTime? _resolveBookingStartDate(Map<String, dynamic> booking) {
    final rawStartDate = booking['startdate'] ?? booking['start_date'];
    if (rawStartDate is Timestamp) return rawStartDate.toDate();
    if (rawStartDate is DateTime) return rawStartDate;
    if (rawStartDate is String) {
      final parsed = DateTime.tryParse(rawStartDate);
      if (parsed != null) return parsed;
    }

    final rawStartTime = booking['start_time'];
    if (rawStartTime is Timestamp) return rawStartTime.toDate();
    if (rawStartTime is DateTime) return rawStartTime;
    if (rawStartTime is String) return DateTime.tryParse(rawStartTime);

    return null;
  }

  /// Generates a list of date strings between start and end (inclusive)
  List<String> _generateDateRange(DateTime start, DateTime end) {
    final dates = <String>[];
    DateTime current = DateTime(start.year, start.month, start.day);
    final endNormalized = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endNormalized)) {
      // Format as YYYY-MM-DD to match your Firebase format
      final dateStr =
          '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      dates.add(dateStr);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Restores availability dates when a booking is cancelled or rejected
  Future<void> _restoreAvailability(String bookingId) async {
    try {
      // Get the booking document
      final bookingDoc =
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingId)
              .get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      final vehicleId = bookingData['vehicle_id'] as String?;
      final startTime = bookingData['start_time'] as Timestamp?;
      final endTime = bookingData['end_time'] as Timestamp?;

      if (vehicleId == null || startTime == null || endTime == null) {
        throw Exception('Missing booking information');
      }

      // Generate the date range that was blocked
      final blockedDates = _generateDateRange(
        startTime.toDate(),
        endTime.toDate(),
      );

      // Add these dates back to the vehicle's availability array
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({'availability': FieldValue.arrayUnion(blockedDates)});

      //print('Restored ${blockedDates.length} dates to vehicle $vehicleId');
    } catch (e) {
      //print('Error restoring availability: $e');
      rethrow;
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject booking?'),
            content: const Text(
              'Are you sure you want to reject this booking request?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Yes, reject'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'status': 'Rejected',
            'rejected_at': FieldValue.serverTimestamp(),
            'rejected_by': user.uid,
          });

      // Restore availability (in case dates were pre-blocked)
      await _restoreAvailability(bookingId);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking rejected')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reject: $e')));
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    if (_isCancelling) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel trip?'),
            content: const Text('Are you sure you want to cancel this trip?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: const Text('Yes, cancel'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      // Determine who is canceling
      final canceledBy = _viewAsHost ? 'by host' : 'by renter';
      
      // Update booking status to Cancelled
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'status': 'Cancelled',
            'cancelled_at': FieldValue.serverTimestamp(),
            'cancelled_by': user.uid,
            'canceled_by': canceledBy, // New field to track who canceled
          });

      // Restore the blocked dates back to availability
      await _restoreAvailability(bookingId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip cancelled and dates restored'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  /// Approves a booking using atomic transaction to prevent double-booking
  /// Blocks the requested dates in vehicle availability
  Future<void> _approveBooking(String bookingId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    if (_isApproving) return; // Prevent double-tap

    setState(() => _isApproving = true);

    try {
      // Use atomic transaction to approve booking and block availability
      final success = await _bookingService.approveBookingWithAvailabilityBlock(
        bookingId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip approved and dates blocked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Display user-friendly error message
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  void _navigateToBookingDetails(String bookingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BookingDetailsScreen(
              bookingId: bookingId,
              isHostView: _viewAsHost,
            ),
      ),
    );
  }

  Future<ImageSource?> _selectVideoSource() {
    return showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Upload walkaround video'),
            content: const Text('Choose how to upload your walkaround video.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text('Record'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text('Gallery'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _startTripWithWalkaroundVideo(String bookingId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    if (_startingTripIds.contains(bookingId)) return;
    setState(() => _startingTripIds.add(bookingId));

    bool loadingShown = false;
    try {
      // print('StartTrip: bookingId=$bookingId');
      // print('StartTrip: user.uid=${user.uid}');
      try {
        final bucket = FirebaseStorage.instance.bucket;
        //print('StartTrip: storageBucket=$bucket');
        //print('StartTrip: projectId=${DefaultFirebaseOptions.currentPlatform.projectId}');

      } catch (_) { 
        // ignore
      }

      // Preflight: validate booking and renter match to help debug auth failures
      final bookingSnap =
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingId)
              .get();
      if (!bookingSnap.exists) {
        throw Exception('Booking not found for id: $bookingId');
      }
      final bookingData = bookingSnap.data() ?? {};
      final renterId = bookingData['renter_id'] as String?;
      if (renterId == null || renterId != user.uid) {
        throw Exception(
          'Renter mismatch. booking.renter_id=$renterId, user.uid=${user.uid}',
        );
      }
      print('StartTrip: booking renter_id matches user');

      final source = await _selectVideoSource();
      if (source == null) return;

      final picked = await _imagePicker.pickVideo(source: source);
      if (picked == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(child: CircularProgressIndicator()),
      );
      loadingShown = true;

      final file = File(picked.path);
      print('StartTrip: picked video path=${picked.path}');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('bookings/$bookingId/start/renter_walkaround.mp4');
      print(
        'StartTrip: upload target=bookings/$bookingId/start/renter_walkaround.mp4',
      );
      await storageRef.putFile(file);
      print('StartTrip: upload complete');
      final url = await storageRef.getDownloadURL();
      print('StartTrip: downloadUrl=$url');

      final confirmStart = FirebaseFunctions.instance.httpsCallable(
        'confirmBookingStart',
      );
      print('StartTrip: calling confirmBookingStart');
      await confirmStart.call({'bookingId': bookingId});
      print('StartTrip: confirmBookingStart success');

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'walkaround_video_url': url,
            'walkaround_video_uploaded_at': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      if (loadingShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip started and walkaround video uploaded.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (e is FirebaseException) {
        print('StartTrip: FirebaseException code=${e.code} message=${e.message}');
      } else {
        print('StartTrip: error=$e');
      }
      if (!mounted) return;
      if (loadingShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start trip: $e')));
    } finally {
      if (mounted) {
        setState(() => _startingTripIds.remove(bookingId));
      }
    }
  }

  Future<List<String>?> _uploadHostEndPhotos(String bookingId) async {
    final photos = await _imagePicker.pickMultiImage();
    if (photos.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photos selected.')),
      );
      return null;
    }

    if (!mounted) return null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final urls = <String>[];
    try {
      for (int i = 0; i < photos.length; i++) {
        final file = File(photos[i].path);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('bookings/$bookingId/end/host/photo_${i + 1}.jpg');
        await storageRef.putFile(file);
        final url = await storageRef.getDownloadURL();
        urls.add(url);
      }

      if (!mounted) return null;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End trip photos uploaded.'),
          backgroundColor: Colors.green,
        ),
      );
      return urls;
    } catch (e) {
      if (!mounted) return null;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload photos: $e')));
      return null;
    }
  }

  Future<void> _endTrip({
    required String bookingId,
    required String actor,
    required bool uploadPhotosBefore,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    if (_endingTripIds.contains(bookingId)) return;
    setState(() => _endingTripIds.add(bookingId));

    bool loadingShown = false;
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      loadingShown = true;

      List<String>? endPhotoUrls;
      if (uploadPhotosBefore) {
        if (loadingShown) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        loadingShown = false;
        endPhotoUrls = await _uploadHostEndPhotos(bookingId);
        if (endPhotoUrls == null || endPhotoUrls.isEmpty) {
          return;
        }
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
        loadingShown = true;
      }

      final confirmEnd = FirebaseFunctions.instance.httpsCallable(
        'confirmBookingEnd',
      );
      await confirmEnd.call({
        'bookingId': bookingId,
        'actor': actor,
        'hasDamage': false,
      });

      if (uploadPhotosBefore && endPhotoUrls != null) {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
              'end_photo_urls': endPhotoUrls,
              'end_photos_uploaded_at': FieldValue.serverTimestamp(),
            });
      }

      if (!mounted) return;
      if (loadingShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip end confirmed.'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      if (loadingShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to end trip: $e')));
    } finally {
      if (mounted) {
        setState(() => _endingTripIds.remove(bookingId));
      }
    }
  }

  Widget _buildUpcomingTab(double screenHeight, double screenWidth) {
    final baseQuery = _baseBookingsQuery();
    if (baseQuery == null) {
      return Center(
        child: Text(
          'Please log in to view your trips.',
          style: TextStyle(fontSize: screenHeight * 0.018),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: baseQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading trips'));
        }

        final docs = snapshot.data?.docs ?? [];
        final DateTime todayStart = _startOfToday();

        final upcomingDocs =
            docs.where((d) {
                final data = d.data();
                if (_isCancelled(data)) return false;
                if (_isCompleted(data)) return false;
                if (_isEnded(data)) return false;
                final endTs = data['end_time'];
                if (endTs is! Timestamp) return false;
                return !endTs.toDate().isBefore(todayStart);
              }).toList()
              ..sort((a, b) {
                final aEnd = (a.data()['end_time'] as Timestamp).toDate();
                final bEnd = (b.data()['end_time'] as Timestamp).toDate();
                return aEnd.compareTo(bEnd);
              });

        if (upcomingDocs.isEmpty) {
          return Center(
            child: Text(
              'No upcoming trips yet.',
              style: TextStyle(fontSize: screenHeight * 0.018),
            ),
          );
        }

        // Group by month header like your UI
        final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        grouped = {};
        for (final d in upcomingDocs) {
          final startTs = d.data()['start_time'];
          if (startTs is! Timestamp) continue;
          final start = startTs.toDate();
          final key = '${start.year}-${start.month}';
          grouped.putIfAbsent(key, () => []).add(d);
        }
        final groupKeys =
            grouped.keys.toList()..sort((a, b) {
              // sort by year-month ascending
              final aParts = a.split('-');
              final bParts = b.split('-');
              final ay = int.parse(aParts[0]);
              final am = int.parse(aParts[1]);
              final by = int.parse(bParts[0]);
              final bm = int.parse(bParts[1]);
              if (ay != by) return ay.compareTo(by);
              return am.compareTo(bm);
            });

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final key in groupKeys) ...[
                Builder(
                  builder: (_) {
                    final parts = key.split('-');
                    final y = int.parse(parts[0]);
                    final m = int.parse(parts[1]);
                    final header = _formatMonthHeader(DateTime(y, m, 1));
                    return Text(
                      header,
                      style: TextStyle(
                        fontSize: screenHeight * 0.02,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    );
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                for (final doc in grouped[key]!) ...[
                  _buildBookingReservationCard(
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                    bookingId: doc.id,
                    booking: doc.data(),
                    isUpcoming: true,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
                SizedBox(height: screenHeight * 0.01),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(double screenHeight, double screenWidth) {
    final baseQuery = _baseBookingsQuery();
    if (baseQuery == null) {
      return Center(
        child: Text(
          'Please log in to view your trips.',
          style: TextStyle(fontSize: screenHeight * 0.018),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: baseQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading trips'));
        }

        final docs = snapshot.data?.docs ?? [];
        final DateTime todayStart = _startOfToday();

        final historyDocs =
            docs.where((d) {
                final data = d.data();
                final endTs = data['end_time'];
                if (endTs is! Timestamp) return false;
                // Show cancelled/completed bookings in history even if they are in the future
                if (_isCancelled(data)) return true;
                if (_isCompleted(data)) return true;
                if (_isEnded(data)) return true;
                return endTs.toDate().isBefore(todayStart);
              }).toList()
              ..sort((a, b) {
                final aEnd = (a.data()['end_time'] as Timestamp).toDate();
                final bEnd = (b.data()['end_time'] as Timestamp).toDate();
                return bEnd.compareTo(aEnd);
              });

        if (historyDocs.isEmpty) {
          return Center(
            child: Text(
              'No trip history yet.',
              style: TextStyle(fontSize: screenHeight * 0.018),
            ),
          );
        }

        // Group by month and show "Reservation History" layout like your UI
        final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        grouped = {};
        for (final d in historyDocs) {
          final endTs = d.data()['end_time'];
          if (endTs is! Timestamp) continue;
          final end = endTs.toDate();
          final key = '${end.year}-${end.month}';
          grouped.putIfAbsent(key, () => []).add(d);
        }
        final groupKeys =
            grouped.keys.toList()..sort((a, b) {
              // show latest months first in history
              final aParts = a.split('-');
              final bParts = b.split('-');
              final ay = int.parse(aParts[0]);
              final am = int.parse(aParts[1]);
              final by = int.parse(bParts[0]);
              final bm = int.parse(bParts[1]);
              if (ay != by) return by.compareTo(ay);
              return bm.compareTo(am);
            });

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar (UI only, same as your design)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.012,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600], size: 20),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      child: Text(
                        'Search with car model, date or location',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: screenHeight * 0.016,
                        ),
                      ),
                    ),
                    Icon(Icons.tune, color: Colors.grey[600], size: 20),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              Text(
                'Reservation History',
                style: TextStyle(
                  fontSize: screenHeight * 0.024,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              for (final key in groupKeys) ...[
                Builder(
                  builder: (_) {
                    // date range header for that month
                    final items = grouped[key]!;
                    final endDates =
                        items
                            .map(
                              (d) =>
                                  (d.data()['end_time'] as Timestamp).toDate(),
                            )
                            .toList()
                          ..sort((a, b) => a.compareTo(b));
                    final startDates =
                        items
                            .map(
                              (d) =>
                                  (d.data()['start_time'] as Timestamp)
                                      .toDate(),
                            )
                            .toList()
                          ..sort((a, b) => a.compareTo(b));
                    final rangeLabel = _formatHistorySectionRange(
                      startDates.first,
                      endDates.last,
                    );
                    return Text(
                      rangeLabel,
                      style: TextStyle(
                        fontSize: screenHeight * 0.018,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    );
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                for (final doc in grouped[key]!) ...[
                  _buildBookingHistoryCard(
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                    booking: doc.data(),
                    status: _statusLabelForBooking(doc.data()),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                ],
                SizedBox(height: screenHeight * 0.02),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingReservationCard({
    required double screenHeight,
    required double screenWidth,
    required String bookingId,
    required Map<String, dynamic> booking,
    required bool isUpcoming,
  }) {
    final vehicleId = (booking['vehicle_id'] as String?) ?? '';
    final start = (booking['start_time'] as Timestamp).toDate();
    final end = (booking['end_time'] as Timestamp).toDate();
    final dateRange = _formatDateRangeShort(start, end);
    final amountPaid = (booking['amount_paid'] as num?)?.toDouble() ?? 0.0;
    final isTripStarted = _isTripStarted(booking);
    final isEndDay = _isEndDay(end);
    final resolvedStart = _resolveBookingStartDate(booking) ?? start;
    final todayStart = _startOfToday();
    final startDay = DateTime(
      resolvedStart.year,
      resolvedStart.month,
      resolvedStart.day,
    );
    final isBeforeStartDay = startDay.isAfter(todayStart);
    final isStartDayOrAfter = !isBeforeStartDay;
    final canStartTripBase =
        !_viewAsHost && isUpcoming && _isApproved(booking) && !isTripStarted;
    final showStartTripButton = canStartTripBase && isStartDayOrAfter;
    final enableStartTripButton = canStartTripBase && isStartDayOrAfter;
    
    // RENTER: Show cancel button when waiting for approval OR when approved but not started
    final showCancelButtonRenter = !_viewAsHost && isUpcoming && !isTripStarted;
    
    // HOST: Show cancel button after approval but before trip starts
    final showCancelButtonHost = _viewAsHost && isUpcoming && _isApproved(booking) && !isTripStarted;
    
    // Combined cancel button logic
    final showCancelButton = showCancelButtonRenter || showCancelButtonHost;
    
    // Only show cancel button alone if before start day (for renter with approved booking)
    final showCancelOnlyButton = showCancelButtonRenter && isBeforeStartDay && _isApproved(booking);
    
    // Show cancel only for renter waiting for approval
    final showCancelOnlyButtonWaiting = !_viewAsHost && _isWaitingForApproval(booking);
    
    // Show cancel only for host after approval before start
    final showCancelOnlyButtonHost = showCancelButtonHost && isBeforeStartDay;
    
    // Show start trip button only (no cancel) - never used now
    final showStartTripOnlyButton = false;
    
    final showCancelDuringTrip = !_viewAsHost && isUpcoming && isTripStarted;
    final showEndTripOnlyButtonForHost =
        _viewAsHost && isUpcoming && isTripStarted && isEndDay;
    final showEndTripOnlyButtonForRenter =
        !_viewAsHost && isUpcoming && isTripStarted && isEndDay;
    final endConfirmations =
        (booking['end_confirmations'] as Map?)?.cast<String, dynamic>() ??
        const {};
    final hostAlreadyConfirmed = endConfirmations['host'] == true;
    final renterAlreadyConfirmed = endConfirmations['renter'] == true;
    final showHostWaitingForRenterEnd =
        _viewAsHost && hostAlreadyConfirmed && !renterAlreadyConfirmed;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadVehicle(vehicleId),
      builder: (context, snap) {
        final vehicle = snap.data;
        final make = (vehicle?['make'] as String?) ?? '';
        final carName = (vehicle?['car_name'] as String?) ?? '';
        final displayName =
            (make.isNotEmpty || carName.isNotEmpty)
                ? '$make $carName'.trim()
                : 'Car';

        final images =
            (vehicle?['images'] as List?)?.cast<String>() ?? const [];
        final imageUrl = images.isNotEmpty ? images.first : '';
        final location = (vehicle?['street_address'] as String?) ?? '';

        return _buildReservationCard(
          screenHeight: screenHeight,
          screenWidth: screenWidth,
          bookingId: bookingId,
          carName: displayName,
          dateRange: dateRange,
          price: 'PKR ${amountPaid.toStringAsFixed(0)}',
          imageUrl: imageUrl,
          location: location.isEmpty ? '—' : location,
          isUpcoming: isUpcoming,
          // Renter should see "Waiting for the approval" once booked.
          showWaitingLabel: !_viewAsHost && _isWaitingForApproval(booking),
          // Host sees Approve button when waiting; after approved, show Cancel/Modify row.
          showApproveButton: _viewAsHost && _isWaitingForApproval(booking),
          showApprovedWaitingBadge: _viewAsHost && _isApproved(booking) && !isTripStarted,
          showStartTripButton: showStartTripButton,
          showTripStartedLabel: false,
          showStartTripOnlyButton: showStartTripOnlyButton,
          showCancelOnlyButton:
              showEndTripOnlyButtonForRenter ? false : (showCancelOnlyButton || showCancelOnlyButtonWaiting || showCancelOnlyButtonHost || showCancelDuringTrip),
          showEndTripOnlyButton:
              (showEndTripOnlyButtonForHost && !hostAlreadyConfirmed) ||
              (showEndTripOnlyButtonForRenter && !renterAlreadyConfirmed),
          showWaitingForRenterToEndButton: showHostWaitingForRenterEnd,
          onStartTrip:
              enableStartTripButton
                  ? () => _startTripWithWalkaroundVideo(bookingId)
                  : null,
          onApprove:
              _viewAsHost && _isWaitingForApproval(booking)
                  ? () async => _approveBooking(bookingId)
                  : null,
          onCancel:
              (showCancelButton || showCancelDuringTrip)
                  ? () async {
                    await _cancelBooking(bookingId);
                  }
                  : null,
          onEndTrip:
              (showEndTripOnlyButtonForHost || showEndTripOnlyButtonForRenter)
                  ? () async {
                    await _endTrip(
                      bookingId: bookingId,
                      actor: _viewAsHost ? 'host' : 'renter',
                      uploadPhotosBefore: _viewAsHost,
                    );
                  }
                  : null,
        );
      },
    );
  }

  Widget _buildBookingHistoryCard({
    required double screenHeight,
    required double screenWidth,
    required Map<String, dynamic> booking,
    required String status,
  }) {
    final vehicleId = (booking['vehicle_id'] as String?) ?? '';
    final start = (booking['start_time'] as Timestamp).toDate();
    final end = (booking['end_time'] as Timestamp).toDate();
    final dateRange = _formatDateRangeShort(start, end);
    final amountPaid = (booking['amount_paid'] as num?)?.toDouble() ?? 0.0;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadVehicle(vehicleId),
      builder: (context, snap) {
        final vehicle = snap.data;
        final make = (vehicle?['make'] as String?) ?? '';
        final carName = (vehicle?['car_name'] as String?) ?? '';
        final displayName =
            (make.isNotEmpty || carName.isNotEmpty)
                ? '$make $carName'.trim()
                : 'Car';

        final images =
            (vehicle?['images'] as List?)?.cast<String>() ?? const [];
        final imageUrl = images.isNotEmpty ? images.first : '';

        return _buildHistoryCard(
          screenHeight: screenHeight,
          screenWidth: screenWidth,
          carName: displayName,
          dateRange: dateRange,
          price: 'PKR ${amountPaid.toStringAsFixed(0)}',
          status: status,
          imageUrl: imageUrl,
        );
      },
    );
  }

  Widget _buildReservationCard({
    required double screenHeight,
    required double screenWidth,
    required String bookingId,
    required String carName,
    required String dateRange,
    required String price,
    required String imageUrl,
    required String location,
    required bool isUpcoming,
    bool showWaitingLabel = false,
    bool showApproveButton = false,
    bool showApprovedWaitingBadge = false,
    bool showStartTripButton = false,
    bool showTripStartedLabel = false,
    bool showStartTripOnlyButton = false,
    bool showCancelOnlyButton = false,
    bool showEndTripOnlyButton = false,
    bool showWaitingForRenterToEndButton = false,
    VoidCallback? onApprove,
    VoidCallback? onStartTrip,
    VoidCallback? onCancel,
    VoidCallback? onEndTrip,
  }) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
          // Car Info Row
          Row(
            children: [
              // Car Image
              Container(
                width: screenWidth * 0.22,
                height: screenHeight * 0.08,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      imageUrl.isNotEmpty
                          ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.directions_car,
                                size: 40,
                                color: Colors.grey,
                              );
                            },
                          )
                          : const Icon(
                            Icons.directions_car,
                            size: 40,
                            color: Colors.grey,
                          ),
                ),
              ),

              SizedBox(width: screenWidth * 0.04),

              // Car Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carName,
                      style: TextStyle(
                        fontSize: screenHeight * 0.02,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      dateRange,
                      style: TextStyle(
                        fontSize: screenHeight * 0.016,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: screenHeight * 0.018,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (showWaitingLabel) ...[
                      SizedBox(height: screenHeight * 0.004),
                      Text(
                        'Waiting for the approval',
                        style: TextStyle(
                          fontSize: screenHeight * 0.014,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.015),

          // Location Info (kept exactly like your UI)
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: screenWidth * 0.01),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    fontSize: screenHeight * 0.015,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.015),

          // Action Buttons (kept like your UI)
          if (isUpcoming)
            Column(
              children: [
                if (showApproveButton)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.lightText,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Approve',
                        style: TextStyle(
                          fontSize: screenHeight * 0.016,
                          color: AppColors.lightText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else if (showCancelOnlyButton) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCancelling ? null : onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        _isCancelling ? 'Cancelling...' : 'Cancel',
                        style: TextStyle(
                          fontSize: screenHeight * 0.016,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else if (showEndTripOnlyButton) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onEndTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.lightText,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        _endingTripIds.contains(bookingId)
                            ? 'Ending...'
                            : 'End Trip',
                        style: TextStyle(
                          fontSize: screenHeight * 0.016,
                          color: AppColors.lightText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else if (showWaitingForRenterToEndButton) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.grey[600],
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Waiting for renter to end',
                        style: TextStyle(
                          fontSize: screenHeight * 0.016,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  if (showStartTripButton || showTripStartedLabel) ...[
                    // Show Start Trip and Cancel buttons in a row when on/after start date
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isCancelling ? null : onCancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              _isCancelling ? 'Cancelling...' : 'Cancel',
                              style: TextStyle(
                                fontSize: screenHeight * 0.016,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: showStartTripButton ? onStartTrip : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.lightText,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[600],
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              showTripStartedLabel ? 'Trip Started' : 'Start Trip',
                              style: TextStyle(
                                fontSize: screenHeight * 0.016,
                                color:
                                    showStartTripButton && onStartTrip == null
                                        ? Colors.grey[600]
                                        : AppColors.lightText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!showStartTripOnlyButton && !showStartTripButton)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isCancelling ? null : onCancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              _isCancelling ? 'Cancelling...' : 'Cancel Trip',
                              style: TextStyle(
                                fontSize: screenHeight * 0.016,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => _navigateToBookingDetails(bookingId),
                            icon: Icon(
                              _viewAsHost ? Icons.visibility : Icons.edit,
                              size: 16,
                              color: AppColors.accent,
                            ),
                            label: Text(
                              _viewAsHost ? 'View Details' : 'Modify',
                              style: TextStyle(
                                fontSize: screenHeight * 0.016,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent.withOpacity(
                                0.1,
                              ),
                              foregroundColor: AppColors.accent,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
        ],
          ),
        ),
        if (showApprovedWaitingBadge)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Waiting for renter to start',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryCard({
    required double screenHeight,
    required double screenWidth,
    required String carName,
    required String dateRange,
    required String price,
    required String status,
    required String imageUrl,
  }) {
    final isCompleted = status == 'Completed';

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Car Image
          Container(
            width: screenWidth * 0.18,
            height: screenHeight * 0.07,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  imageUrl.isNotEmpty
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.directions_car,
                            size: 35,
                            color: Colors.grey,
                          );
                        },
                      )
                      : const Icon(
                        Icons.directions_car,
                        size: 35,
                        color: Colors.grey,
                      ),
            ),
          ),

          SizedBox(width: screenWidth * 0.04),

          // Car Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  carName,
                  style: TextStyle(
                    fontSize: screenHeight * 0.019,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  dateRange,
                  style: TextStyle(
                    fontSize: screenHeight * 0.015,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Row(
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: screenHeight * 0.016,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: screenHeight * 0.015,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? AppColors.accent : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Rebook Button
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.refresh, size: 16, color: AppColors.accent),
            label: Text(
              'Rebook',
              style: TextStyle(
                fontSize: screenHeight * 0.015,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.01,
              ),
              side: BorderSide(color: AppColors.accent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}