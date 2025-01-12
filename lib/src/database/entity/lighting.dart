import 'entity.dart';

class Lighting extends Entity<Lighting> {
  Lighting({
    required super.id,
    required this.lightSwitchId,
    required super.createdDate,
    required super.modifiedDate,
  }) : super();

  Lighting.forInsert({
    required this.lightSwitchId,
  }) : super.forInsert();

  Lighting.forUpdate({
    required super.entity,
    required this.lightSwitchId,
  }) : super.forUpdate();

  factory Lighting.fromMap(Map<String, dynamic> map) => Lighting(
        id: map['id'] as int,
        lightSwitchId: map['light_switch_id'] as int,
        createdDate: DateTime.parse(map['created_date'] as String),
        modifiedDate: DateTime.parse(map['modified_date'] as String),
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'light_switch_id': lightSwitchId,
        'created_date': createdDate.toIso8601String(),
        'modified_date': modifiedDate.toIso8601String(),
      };

  int lightSwitchId; // References an EndPoint

  @override
  String get name => 'Lighting $id'; // Replace with a meaningful name logic
}
