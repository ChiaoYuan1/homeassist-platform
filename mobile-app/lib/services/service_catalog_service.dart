import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_models.dart';

class ServiceCatalogService {
  final FirebaseFirestore _firestore;
  ServiceCatalogService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<ServiceCategoryModel>> getCategories() async {
    final snapshot = await _firestore.collection('serviceCategories').where(
        'active',
        isEqualTo: true
    ).get();
    final result = snapshot.docs.map((doc) => ServiceCategoryModel.fromMap(
        doc.id,
        doc.data()
    )).toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  Future<List<ServiceItemModel>> getServicesByCategory(String categoryId) async {
    final snapshot = await _firestore.collection('services').where(
        'categoryId',
        isEqualTo: categoryId
    ).where(
        'active',
        isEqualTo: true
    ).get();
    final result = snapshot.docs.map((doc) => ServiceItemModel.fromMap(
        doc.id,
        doc.data()
    )).toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  Future<List<ServiceItemModel>> getServicesByIds(List<String> ids) async {
    final docs = await Future.wait(ids.map((id) => _firestore.collection('services').doc(id).get()));
    return docs.where((d) => d.exists).map((d) => ServiceItemModel.fromMap(
        d.id,
        d.data()!
    )).toList();
  }
}
