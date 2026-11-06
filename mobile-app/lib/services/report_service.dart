import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_enums.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore;
  ReportService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createReport({
    required String reporterId,
    required String providerId,
    required String subject,
    required String description,
    String? bookingId
  }) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'providerId': providerId,
      'bookingId': bookingId,
      'subject': subject.trim(),
      'description': description.trim(),
      'status': ReportStatus.open.value,
      'createdAt': FieldValue.serverTimestamp()
    });
  }

  Future<List<ReportModel>> getReports() async {
    final s = await _firestore.collection('reports').get();
    final r = s.docs.map((d) => ReportModel.fromMap(
        d.id,
        d.data()
    )).toList();
    r.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return r;
  }

  Future<void> updateStatus({
    required String reportId,
    required ReportStatus status
  }) => _firestore.collection('reports').doc(reportId).update({
    'status': status.value,
    'updatedAt': FieldValue.serverTimestamp()
  });
}
