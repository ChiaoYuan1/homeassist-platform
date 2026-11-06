import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_enums.dart';

class ProviderReviewSummary {
  final double averageRating;
  final int reviewCount;

  const ProviderReviewSummary({
    required this.averageRating,
    required this.reviewCount,
  });
}

class ReviewService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReviewService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<bool> hasReviewedBooking(String bookingId) async {
    final review = await _firestore
        .collection('reviews')
        .doc(bookingId)
        .get();

    return review.exists;
  }

  Future<void> submitReview({
    required String bookingId,
    required int rating,
    String comment = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in before submitting a review.');
    }

    if (rating < 1 || rating > 5) {
      throw ArgumentError('Select a rating from 1 to 5 stars.');
    }

    final cleanedComment = comment.trim();
    if (cleanedComment.length > 500) {
      throw ArgumentError('Review must contain 500 characters or fewer.');
    }

    final bookingReference = _firestore.collection('bookings').doc(bookingId);
    final reviewReference = _firestore.collection('reviews').doc(bookingId);

    // The booking ID is the review document ID, so a booking can
    // have only one review. Both reads occur before the transaction write.
    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingReference);
      final reviewSnapshot = await transaction.get(reviewReference);

      if (!bookingSnapshot.exists) {
        throw StateError('Booking not found.');
      }

      if (reviewSnapshot.exists) {
        throw StateError('A review has already been submitted for this booking.');
      }

      final booking = bookingSnapshot.data()!;
      if (booking['customerId'] != user.uid) {
        throw StateError('Only the booking customer may submit a review.');
      }

      if (booking['status'] != BookingStatus.completed.value) {
        throw StateError('Reviews are available after service completion.');
      }

      final providerId = booking['providerId']?.toString() ?? '';
      if (providerId.isEmpty) {
        throw StateError('This booking has no provider assigned.');
      }

      transaction.set(reviewReference, {
        'bookingId': bookingId,
        'customerId': user.uid,
        'providerId': providerId,
        'rating': rating,
        'comment': cleanedComment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Calculates ratings from submitted reviews without letting a customer
  // directly edit a provider's rating/reviewCount fields.
  Future<ProviderReviewSummary> getProviderSummary(String providerId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('providerId', isEqualTo: providerId)
        .get();

    var total = 0;
    var count = 0;

    for (final document in snapshot.docs) {
      final rating = (document.data()['rating'] as num?)?.toInt();
      if (rating == null || rating < 1 || rating > 5) {
        continue;
      }

      total += rating;
      count++;
    }

    return ProviderReviewSummary(
      averageRating: count == 0 ? 0 : total / count,
      reviewCount: count,
    );
  }
}
