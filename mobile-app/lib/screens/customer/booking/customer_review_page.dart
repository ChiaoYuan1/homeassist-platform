
import 'package:flutter/material.dart';

import '../../../models/booking_model.dart';
import '../../../services/review_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/homeassist_action_dialog.dart';

class CustomerReviewPage extends StatefulWidget {
  final BookingModel booking;

  const CustomerReviewPage({
    super.key,
    required this.booking,
  });

  @override
  State<CustomerReviewPage> createState() =>
      _CustomerReviewPageState();
}

class _CustomerReviewPageState extends State<CustomerReviewPage> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController =
  TextEditingController();

  late final Future<bool> _existingReview;

  int _rating = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _existingReview = _reviewService.hasReviewedBooking(
      widget.booking.id,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // =========================================================
  // SUBMIT REVIEW
  // =========================================================

  Future<void> _submit() async {
    if (_submitting || _rating == 0) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _reviewService.submitReview(
        bookingId: widget.booking.id,
        rating: _rating,
        comment: _commentController.text,
      );

      if (!mounted) {
        return;
      }

      // Reuse the shared HomeAssist success dialog.
      await showHomeAssistSuccessDialog(
        context: context,
        title: 'Review Submitted!',
        message: 'Thank you for your feedback. '
            'Your review has been submitted successfully.',
      );

      if (!mounted) {
        return;
      }

      // Return to the customer's booking status page
      // after the Done button is pressed.
      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('Unable to submit review: $error');

      if (!mounted) {
        return;
      }

      // Reuse the shared HomeAssist error dialog.
      await showHomeAssistMessageDialog(
        context: context,
        title: 'Unable to Submit Review',
        message: 'Your review could not be submitted. '
            'Please try again.',
        type: HomeAssistMessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Service'),
      ),
      body: FutureBuilder<bool>(
        future: _existingReview,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to check review status. '
                      'Please try again.',
                ),
              ),
            );
          }

          if (snapshot.data == true) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'A review has already been submitted '
                      'for this booking.',
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'How was your service?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Rate the completed service '
                    'from 1 to 5 stars.',
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;

                  return IconButton(
                    tooltip: '$value star${value == 1 ? '' : 's'}',
                    onPressed: _submitting
                        ? null
                        : () {
                      setState(() {
                        _rating = value;
                      });
                    },
                    icon: Icon(
                      value <= _rating
                          ? Icons.star
                          : Icons.star_border,
                      color: const Color(0xFFE9A23B),
                      size: 34,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _commentController,
                enabled: !_submitting,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Review (optional)',
                  hintText:
                  'Share your experience with this provider.',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _rating == 0 || _submitting
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
                child: Text(
                  _submitting
                      ? 'Submitting...'
                      : 'Submit Review',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
