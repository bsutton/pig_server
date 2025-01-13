import 'endpoint.dart';
import 'entity.dart';
import 'garden_feature.dart';

class Lighting extends Entity<Lighting> implements GardenFeature {
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

  /// id of [EndPoint] for this light
  int lightSwitchId;

  @override
  String get name => 'Lighting $id';

  @override
  int getPrimaryEndPoint() => lightSwitchId;
}
