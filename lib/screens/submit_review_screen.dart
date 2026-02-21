import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SubmitReviewScreen extends StatefulWidget {
  final String bookingId;
  final String actor; // "renter" or "host"

  const SubmitReviewScreen({
    super.key,
    required this.bookingId,
    required this.actor,
  });

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  final TextEditingController _carCommentController = TextEditingController();
  final TextEditingController _hostCommentController = TextEditingController();
  final TextEditingController _renterCommentController = TextEditingController();

  int _renterToCarRating = 0;
  int _renterToHostRating = 0;
  int _hostToRenterRating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _carCommentController.dispose();
    _hostCommentController.dispose();
    _renterCommentController.dispose();
    super.dispose();
  }

  Widget _buildStarRow({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: List.generate(5, (index) {
        final star = index + 1;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36),
          onPressed: () => onChanged(star),
          icon: Icon(
            star <= value ? Icons.star : Icons.star_border,
            color: AppColors.ratingStar,
            size: 30,
          ),
        );
      }),
    );
  }

  Widget _buildReviewSection({
    required String title,
    required String subtitle,
    required int rating,
    required ValueChanged<int> onRatingChanged,
    required TextEditingController commentController,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          _buildStarRow(value: rating, onChanged: onRatingChanged),
          const SizedBox(height: 20),
          const Text(
            'Tell us what can be improved',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Optional comment',
              hintStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 0.1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent, width: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_submitting) return;

    if (widget.actor == 'renter') {
      if (_renterToCarRating < 1 || _renterToHostRating < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide both car and host ratings.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_hostToRenterRating < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide renter rating.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('submitBookingReview');
      if (widget.actor == 'renter') {
        await callable.call({
          'bookingId': widget.bookingId,
          'actor': 'renter',
          'renter_to_car': {
            'rating': _renterToCarRating,
            'comment': _carCommentController.text.trim(),
          },
          'renter_to_host': {
            'rating': _renterToHostRating,
            'comment': _hostCommentController.text.trim(),
          },
        });
      } else {
        await callable.call({
          'bookingId': widget.bookingId,
          'actor': 'host',
          'host_to_renter': {
            'rating': _hostToRenterRating,
            'comment': _renterCommentController.text.trim(),
          },
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final message = e.message ?? 'Failed to submit review.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRenter = widget.actor == 'renter';
    return Scaffold(
      backgroundColor: AppColors.foreground,
      appBar: AppBar(
        backgroundColor: AppColors.foreground,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        title: const Text('Add Review'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (isRenter) ...[
                        _buildReviewSection(
                          title: 'Rate the Car',
                          subtitle: 'How was your experience with this car?',
                          rating: _renterToCarRating,
                          onRatingChanged:
                              (value) => setState(() => _renterToCarRating = value),
                          commentController: _carCommentController,
                        ),
                        _buildReviewSection(
                          title: 'Rate the Host',
                          subtitle: 'How was your experience with the host?',
                          rating: _renterToHostRating,
                          onRatingChanged:
                              (value) => setState(() => _renterToHostRating = value),
                          commentController: _hostCommentController,
                        ),
                      ] else ...[
                        _buildReviewSection(
                          title: 'Rate the Renter',
                          subtitle: 'How was your experience with the renter?',
                          rating: _hostToRenterRating,
                          onRatingChanged:
                              (value) => setState(() => _hostToRenterRating = value),
                          commentController: _renterCommentController,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.lightText,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_submitting ? 'Submitting...' : 'Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
