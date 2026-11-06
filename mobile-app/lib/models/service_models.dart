class ServiceCategoryModel {
  final String id;
  final String name;
  final String description;
  final bool active;
  const ServiceCategoryModel({required this.id, required this.name, required this.description, this.active = true});
  factory ServiceCategoryModel.fromMap(String id, Map<String, dynamic> data) => ServiceCategoryModel(
    id: id,
    name: data['name'] ?? '',
    description: data['description'] ?? '',
    active: data['active'] ?? true,
  );
  Map<String, dynamic> toMap() => {'name': name, 'description': description, 'active': active};
}

class ServiceItemModel {
  final String id;
  final String categoryId;
  final String name;
  final int defaultDurationMinutes;
  final bool supportsBrandPreference;
  final bool active;
  const ServiceItemModel({required this.id, required this.categoryId, required this.name, required this.defaultDurationMinutes, this.supportsBrandPreference = false, this.active = true});
  factory ServiceItemModel.fromMap(String id, Map<String, dynamic> data) => ServiceItemModel(
    id: id,
    categoryId: data['categoryId'] ?? '',
    name: data['name'] ?? '',
    defaultDurationMinutes: (data['defaultDurationMinutes'] as num?)?.toInt() ?? 60,
    supportsBrandPreference: data['supportsBrandPreference'] ?? false,
    active: data['active'] ?? true,
  );
  Map<String, dynamic> toMap() => {
    'categoryId': categoryId,
    'name': name,
    'defaultDurationMinutes': defaultDurationMinutes,
    'supportsBrandPreference': supportsBrandPreference,
    'active': active,
  };
}
