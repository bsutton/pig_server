import '../database/entity/garden_feature.dart';

abstract class TimerNotification {
  void timerStarted(GardenFeature feature, Duration duration);

  void timerFinished(GardenFeature feature);
}
