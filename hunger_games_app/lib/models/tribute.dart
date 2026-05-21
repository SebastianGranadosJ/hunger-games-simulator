class ItemModel {
  final int? id;
  final String name;

  ItemModel({this.id, required this.name});

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as int?,
      name: json['name'] as String,
    );
  }
}

class TributeModel {
  final int? id;
  final String name;
  final String gender;
  final int district;
  final List<ItemModel> items;
  final List<String> stateNotes;
  final bool isAlive;
  final int kills;

  TributeModel({
    this.id,
    required this.name,
    required this.gender,
    required this.district,
    required this.items,
    required this.stateNotes,
    required this.isAlive,
    required this.kills,
  });

  String get idString => id?.toString() ?? '';

  factory TributeModel.fromJson(Map<String, dynamic> json) {
    return TributeModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      gender: json['gender'] as String,
      district: json['district'] as int,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stateNotes: (json['state_notes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isAlive: json['is_alive'] as bool,
      kills: json['kills'] as int,
    );
  }
}
