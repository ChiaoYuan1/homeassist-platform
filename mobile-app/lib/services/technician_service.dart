import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_enums.dart';
import '../models/provider_models.dart';

class TechnicianService {
  final FirebaseFirestore _firestore;
  TechnicianService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  //ALL Technicians
  Future<List<TechnicianModel>> getTechnicians(String providerId) async {
    final s = await _firestore.collection('providers').doc(providerId).collection('technicians').get();
    return s.docs.map((d) => TechnicianModel.fromMap(
        d.id,
        providerId,
        d.data()
    )).toList();
  }

  Future<TechnicianModel?> getTechnician({
    required String providerId,
    required String technicianId,
  }) async {
    final doc = await _firestore
        .collection('providers')
        .doc(providerId)
        .collection('technicians')
        .doc(technicianId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return TechnicianModel.fromMap(
      doc.id,
      providerId,
      doc.data()!,
    );
  }

  Future<List<TechnicianModel>> getQualifiedActiveTechnicians({
    required String providerId,
    required List<String> serviceIds
  }) async {
    final t = await getTechnicians(providerId);
    return t.where(
            (x) => x.active &&
            serviceIds.every(x.serviceIds.contains)
    ).toList();
  }

  Future<void> addTechnician({
    required String providerId,
    required String name,
    required String phone,
    required List<String> serviceIds
  }) async {
    await _firestore.collection('providers').doc(providerId).collection('technicians').add({
      'name': name.trim(),
      'phone': phone.trim(),
      'active': true,
      'serviceIds': serviceIds,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setTechnicianActive({
    required String providerId,
    required String technicianId,
    required bool active
  }) => _firestore.collection('providers').doc(providerId).collection('technicians').doc(technicianId).update({'active': active});

  Future<void> addUnavailableOverride({
    required String providerId,
    required String technicianId,
    required DateTime start,
    required DateTime end,
    required String reason
  }) async {
    await _firestore.collection('availabilityOverrides').add({
      'providerId': providerId,
      'technicianId': technicianId,
      'startAt': Timestamp.fromDate(start),
      'endAt': Timestamp.fromDate(end),
      'type': AvailabilityOverrideType.unavailable.name,
      'reason': reason.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
