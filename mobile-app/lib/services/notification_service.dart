import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  NotificationService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String? bookingId
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'bookingId': bookingId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp()
    });
  }

  Stream<List<NotificationModel>> watchForUser(String userId) => _firestore.collection('notifications').where(
      'userId',
      isEqualTo: userId
  ).snapshots().map((s) {
    final items = s.docs.map((d) => NotificationModel.fromMap(
        d.id,
        d.data()
    )).toList();
    items.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return items;
  });

  Future<void> markRead(String id) => _firestore.collection('notifications').doc(id).update({'read': true});
}
