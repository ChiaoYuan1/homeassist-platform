import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_enums.dart';

class ReportModel {
  final String id;
  final String reporterId;
  final String providerId;
  final String? bookingId;
  final String subject;
  final String description;
  final ReportStatus status;
  final DateTime? createdAt;
  const ReportModel({required this.id, required this.reporterId, required this.providerId, required this.subject, required this.description, required this.status, this.bookingId, this.createdAt});
  factory ReportModel.fromMap(String id, Map<String, dynamic> data) => ReportModel(
    id: id,
    reporterId: data['reporterId'] ?? '',
    providerId: data['providerId'] ?? '',
    bookingId: data['bookingId'],
    subject: data['subject'] ?? '',
    description: data['description'] ?? '',
    status: ReportStatusX.fromValue(data['status'] ?? 'open'),
    createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
  );
}
