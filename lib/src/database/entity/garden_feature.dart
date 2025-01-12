import '../entity/history.dart';
import 'entity.dart';

abstract class GardenFeature<T extends GardenFeature<T>> extends Entity<T> {
  GardenFeature({
    required super.id,
    required this.historyList,
    required super.createdDate,
    required super.modifiedDate,
  }) : super();

  GardenFeature.forInsert({
    required this.historyList,
  }) : super.forInsert();

  GardenFeature.forUpdate({
    required super.entity,
    required this.historyList,
  }) : super.forUpdate();

  factory GardenFeature.fromMap(Map<String, dynamic> _) {
    throw UnimplementedError(
        'GardenFeature.fromMap must be overridden in subclasses');
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'created_date': createdDate.toIso8601String(),
        'modified_date': modifiedDate.toIso8601String(),
      };

  List<History> historyList = [];

  /// Abstract methods to be implemented by subclasses
  String get name;
  // moved to dao.
  // bool get isOn;

  void addHistory(History history) {
    historyList.insert(0, history);
  }

  void removeHistory(History history) {
    historyList.remove(history);
  }

  History? get lastEvent => historyList.isNotEmpty ? historyList.first : null;
}
