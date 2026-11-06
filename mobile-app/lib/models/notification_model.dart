import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String? bookingId;
  final bool read;
  final DateTime? createdAt;
  const NotificationModel({required this.id, required this.userId, required this.title, required this.message, required this.read, this.bookingId, this.createdAt});
  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) => NotificationModel(
    id: id,
    userId: data['userId'] ?? '',
    title: data['title'] ?? '',
    message: data['message'] ?? '',
    bookingId: data['bookingId'],
    read: data['read'] ?? false,
    createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
  );
}
