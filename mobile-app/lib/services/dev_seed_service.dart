import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_models.dart';

class DevSeedService {
  final FirebaseFirestore _firestore;
  DevSeedService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> seedCoreCatalogue() async {
    const categories = [
      ServiceCategoryModel(
          id: 'plumbing',
          name: 'Plumbing',
          description: 'Pipe, drain, tap and toilet services.'
      ),
      ServiceCategoryModel(
          id: 'electrical',
          name: 'Electrical',
          description: 'Sockets, wiring, lighting and power issues.'
      ),
      ServiceCategoryModel(
          id: 'appliance_repair',
          name: 'Appliance Repair',
          description: 'Repair common household appliances.'
      ),
      ServiceCategoryModel(
          id: 'gas_replacement',
          name: 'Gas Tank Replacement',
          description: 'Household gas cylinder replacement.'
      ),
    ];
    const services = [
      ServiceItemModel(
          id: 'leaking_pipe',
          categoryId: 'plumbing',
          name: 'Leaking Pipe',
          defaultDurationMinutes: 60
      ),
      ServiceItemModel(
          id: 'clogged_drain',
          categoryId: 'plumbing',
          name: 'Clogged Drain',
          defaultDurationMinutes: 60
      ),
      ServiceItemModel(
          id: 'broken_tap',
          categoryId: 'plumbing',
          name: 'Broken Tap',
          defaultDurationMinutes: 45
      ),
      ServiceItemModel(
          id: 'toilet_problem',
          categoryId: 'plumbing',
          name: 'Toilet Problem',
          defaultDurationMinutes: 60
      ),
      ServiceItemModel(
          id: 'power_outage',
          categoryId: 'electrical',
          name: 'Power Outage',
          defaultDurationMinutes: 90
      ),
      ServiceItemModel(
          id: 'faulty_socket',
          categoryId: 'electrical',
          name: 'Faulty Socket',
          defaultDurationMinutes: 45
      ),
      ServiceItemModel(
          id: 'wiring_problem',
          categoryId: 'electrical',
          name: 'Wiring Problem',
          defaultDurationMinutes: 120
      ),
      ServiceItemModel(
          id: 'light_problem',
          categoryId: 'electrical',
          name: 'Light Problem',
          defaultDurationMinutes: 45
      ),
      ServiceItemModel(
          id: 'air_conditioner',
          categoryId: 'appliance_repair',
          name: 'Air Conditioner',
          defaultDurationMinutes: 90
      ),
      ServiceItemModel(
          id: 'refrigerator',
          categoryId: 'appliance_repair',
          name: 'Refrigerator',
          defaultDurationMinutes: 120
      ),
      ServiceItemModel(
          id: 'washing_machine',
          categoryId: 'appliance_repair',
          name: 'Washing Machine',
          defaultDurationMinutes: 90
      ),
      ServiceItemModel(
          id: 'water_heater',
          categoryId: 'appliance_repair',
          name: 'Water Heater',
          defaultDurationMinutes: 90
      ),
      ServiceItemModel(
          id: 'gas_tank_replacement',
          categoryId: 'gas_replacement',
          name: 'Gas Tank Replacement',
          defaultDurationMinutes: 30,
          supportsBrandPreference: true
      ),
    ];
    final b = _firestore.batch();

    for (final c in categories) {
      b.set(
        _firestore.collection('serviceCategories').doc(c.id),
        {
          ...c.toMap(),
          'active': true,
        },
        SetOptions(merge: true),
      );
    }

    for (final s in services) {
      b.set(
        _firestore.collection('services').doc(s.id),
        {
          ...s.toMap(),
          'active': true,
        },
        SetOptions(merge: true),
      );
    }

    await b.commit();
  }
}
