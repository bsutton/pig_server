import 'entities.dart';

class History extends Entity<History> {
  History({
    required super.id,
    required this.gardenFeatureId,
    required this.eventStart,
    required super.createdDate,
    required super.modifiedDate,
    this.eventDuration,
  }) : super();

  History.forInsert({
    required this.gardenFeatureId,
    required this.eventStart,
    this.eventDuration,
  }) : super.forInsert();

  History.forUpdate({
    required super.entity,
    required this.gardenFeatureId,
    required this.eventStart,
    this.eventDuration,
  }) : super.forUpdate();

  factory History.fromMap(Map<String, dynamic> map) => History(
        id: map['id'] as int,
        gardenFeatureId: map['garden_feature_id'] as int,
        eventStart: DateTime.parse(map['event_start'] as String),
        eventDuration: map['event_duration'] != null
            ? Duration(seconds: map['event_duration'] as int)
            : null,
        createdDate: DateTime.parse(map['created_date'] as String),
        modifiedDate: DateTime.parse(map['modified_date'] as String),
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'garden_feature_id': gardenFeatureId,
        'event_start': eventStart.toIso8601String(),
        'event_duration': eventDuration?.inSeconds,
        'created_date': createdDate.toIso8601String(),
        'modified_date': modifiedDate.toIso8601String(),
      };

  int gardenFeatureId;
  DateTime eventStart;
  Duration? eventDuration;

  void markEventComplete() {
    eventDuration = DateTime.now().difference(eventStart);
  }

  bool get isComplete => eventDuration != null;
}
