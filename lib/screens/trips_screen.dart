import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TripsScreen extends StatefulWidget {
  /// If true, show trips as HOST (bookings where owner_id == current user).
  /// If false, show trips as RENTER (bookings where renter_id == current user).
  final bool viewAsHost;

  const TripsScreen({super.key, this.viewAsHost = false});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final bool _viewAsHost;
  bool _isCancelling = false;

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
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'History'),
                  ],
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

  String _formatMonthHeader(DateTime date) => '${_monthName(date.month)} ${date.year}';

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
      final doc = await FirebaseFirestore.instance.collection('vehicles').doc(vehicleId).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  String _statusLabelForBooking(Map<String, dynamic> booking) {
    final raw = (booking['status'] as String?)?.trim().toLowerCase();
    if (raw == 'cancelled' || raw == 'canceled') return 'Cancelled';
    if (raw == 'approved') return 'Approved';
    if (raw == 'completed') return 'Completed';
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

  bool _isWaitingForApproval(Map<String, dynamic> booking) {
    final raw = (booking['status'] as String?)?.trim().toLowerCase();
    return raw == 'waiting for the approval' || raw == 'waiting';
  }

  // (reserved for future use) approved check can be added when Modify depends on it

  Future<void> _cancelBooking(String bookingId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    if (_isCancelling) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel trip?'),
        content: const Text('Are you sure you want to cancel this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'Cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
        'cancelled_by': user.uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _approveBooking(String bookingId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'Approved',
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by': user.uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip approved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve: $e')),
      );
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

        final upcomingDocs = docs.where((d) {
          final data = d.data();
          if (_isCancelled(data)) return false;
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
        final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped = {};
        for (final d in upcomingDocs) {
          final startTs = d.data()['start_time'];
          if (startTs is! Timestamp) continue;
          final start = startTs.toDate();
          final key = '${start.year}-${start.month}';
          grouped.putIfAbsent(key, () => []).add(d);
        }
        final groupKeys = grouped.keys.toList()
          ..sort((a, b) {
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

        final historyDocs = docs.where((d) {
          final data = d.data();
          final endTs = data['end_time'];
          if (endTs is! Timestamp) return false;
          // Show cancelled bookings in history even if they are in the future
          if (_isCancelled(data)) return true;
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
        final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped = {};
        for (final d in historyDocs) {
          final endTs = d.data()['end_time'];
          if (endTs is! Timestamp) continue;
          final end = endTs.toDate();
          final key = '${end.year}-${end.month}';
          grouped.putIfAbsent(key, () => []).add(d);
        }
        final groupKeys = grouped.keys.toList()
          ..sort((a, b) {
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
                    final endDates = items
                        .map((d) => (d.data()['end_time'] as Timestamp).toDate())
                        .toList()
                      ..sort((a, b) => a.compareTo(b));
                    final startDates = items
                        .map((d) => (d.data()['start_time'] as Timestamp).toDate())
                        .toList()
                      ..sort((a, b) => a.compareTo(b));
                    final rangeLabel =
                        _formatHistorySectionRange(startDates.first, endDates.last);
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

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadVehicle(vehicleId),
      builder: (context, snap) {
        final vehicle = snap.data;
        final make = (vehicle?['make'] as String?) ?? '';
        final carName = (vehicle?['car_name'] as String?) ?? '';
        final displayName =
            (make.isNotEmpty || carName.isNotEmpty) ? '$make $carName'.trim() : 'Car';

        final images = (vehicle?['images'] as List?)?.cast<String>() ?? const [];
        final imageUrl = images.isNotEmpty ? images.first : '';
        final location = (vehicle?['street_address'] as String?) ?? '';

        return _buildReservationCard(
          screenHeight: screenHeight,
          screenWidth: screenWidth,
          carName: displayName,
          dateRange: dateRange,
          price: 'PKR ${amountPaid.toStringAsFixed(0)}',
          imageUrl: imageUrl.isEmpty ? 'https://via.placeholder.com/100x80' : imageUrl,
          location: location.isEmpty ? '—' : location,
          isUpcoming: isUpcoming,
          // Renter should see "Waiting for the approval" once booked.
          showWaitingLabel: !_viewAsHost && _isWaitingForApproval(booking),
          // Host sees Approve button when waiting; after approved, show Cancel/Modify row.
          showApproveButton: _viewAsHost && _isWaitingForApproval(booking),
          onApprove: _viewAsHost && _isWaitingForApproval(booking)
              ? () async => _approveBooking(bookingId)
              : null,
          onCancel: isUpcoming
              ? () async {
                  await _cancelBooking(bookingId);
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
            (make.isNotEmpty || carName.isNotEmpty) ? '$make $carName'.trim() : 'Car';

        final images = (vehicle?['images'] as List?)?.cast<String>() ?? const [];
        final imageUrl = images.isNotEmpty ? images.first : '';

        return _buildHistoryCard(
          screenHeight: screenHeight,
          screenWidth: screenWidth,
          carName: displayName,
          dateRange: dateRange,
          price: 'PKR ${amountPaid.toStringAsFixed(0)}',
          status: status,
          imageUrl: imageUrl.isEmpty ? 'https://via.placeholder.com/100x80' : imageUrl,
        );
      },
    );
  }

  // ---- Original UI widgets (kept consistent) ----

  Widget _buildReservationCard({
    required double screenHeight,
    required double screenWidth,
    required String carName,
    required String dateRange,
    required String price,
    required String imageUrl,
    required String location,
    required bool isUpcoming,
    bool showWaitingLabel = false,
    bool showApproveButton = false,
    VoidCallback? onApprove,
    VoidCallback? onCancel,
  }) {
    return Container(
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
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.directions_car, size: 40, color: Colors.grey);
                    },
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
            (showApproveButton
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.lightText,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
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
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isCancelling ? null : onCancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
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
                          onPressed: () {},
                          icon: Icon(Icons.edit, size: 16, color: AppColors.accent),
                          label: Text(
                            'Modify',
                            style: TextStyle(
                              fontSize: screenHeight * 0.016,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent.withOpacity(0.1),
                            foregroundColor: AppColors.accent,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
        ],
      ),
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
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.directions_car, size: 35, color: Colors.grey);
                },
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