import 'package:pig_common/pig_common.dart';

abstract class TimerNotification {
  void timerStarted(GardenFeature feature, Duration duration);

  void timerFinished(GardenFeature feature);
}
