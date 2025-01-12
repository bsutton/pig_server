import 'entity.dart';

class GardenBed extends Entity<GardenBed> {
  GardenBed({
    required super.id,
    required this.name,
    required this.description,
    required this.moistureContent,
    required this.valveId,
    required super.createdDate,
    required super.modifiedDate,
    this.nextWatering,
    this.masterValveId,
  }) : super();

  GardenBed.forInsert({
    required this.name,
    required this.description,
    required this.moistureContent,
    required this.valveId,
    this.nextWatering,
    this.masterValveId,
  }) : super.forInsert();

  GardenBed.forUpdate({
    required super.entity,
    required this.name,
    required this.description,
    required this.moistureContent,
    required this.valveId,
    this.nextWatering,
    this.masterValveId,
  }) : super.forUpdate();

  factory GardenBed.fromMap(Map<String, dynamic> map) => GardenBed(
        id: map['id'] as int,
        name: map['name'] as String,
        description: map['description'] as String,
        nextWatering: map['next_watering'] != null
            ? DateTime.parse(map['next_watering'] as String)
            : null,
        moistureContent: map['moisture_content'] as int,
        valveId: map['valve_id'] as int,
        masterValveId: map['master_valve_id'] as int?,
        createdDate: DateTime.parse(map['created_date'] as String),
        modifiedDate: DateTime.parse(map['modified_date'] as String),
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'next_watering': nextWatering?.toIso8601String(),
        'moisture_content': moistureContent,
        'valve_id': valveId,
        'master_valve_id': masterValveId,
        'created_date': createdDate.toIso8601String(),
        'modified_date': modifiedDate.toIso8601String(),
      };

  @override
  String name;
  String description;
  DateTime? nextWatering;
  int moistureContent;
  int valveId; // Foreign key for the valve
  int? masterValveId;
}
