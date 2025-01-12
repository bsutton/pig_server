import 'garden_feature.dart';

class Lighting extends GardenFeature<Lighting> {
  Lighting({
    required super.id,
    required this.lightSwitchId,
    required super.historyList,
    required super.createdDate,
    required super.modifiedDate,
  }) : super();

  Lighting.forInsert({
    required this.lightSwitchId,
    required super.historyList,
  }) : super.forInsert();

  Lighting.forUpdate({
    required super.entity,
    required this.lightSwitchId,
    required super.historyList,
  }) : super.forUpdate();

  factory Lighting.fromMap(Map<String, dynamic> map) => Lighting(
        id: map['id'] as int,
        lightSwitchId: map['light_switch_id'] as int,
        historyList: [], // History will be loaded separately
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

  @override
  bool get isOn =>
      false; // Logic should be implemented to check the light status
}
