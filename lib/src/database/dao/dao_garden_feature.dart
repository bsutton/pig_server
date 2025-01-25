import 'dart:async';

import 'package:pig_common/pig_common.dart';

import '../../controllers/end_point_bus.dart';
import '../../controllers/timer_control.dart';
import 'dao_endpoint.dart';
import 'dao_history.dart';

/// Data Access Object for performing operations on [GardenFeature].
///
/// Methods ported from the Java [GardenFeature] class into a DAO-based
/// approach.
/// The [GardenFeature] entity is now a simple data class, and any logic that
/// modifies or creates [History] records or triggers [TimerControl] goes here.
mixin DaoGardenFeature {
  /// Marks a [GardenFeature] as turned on, creating a new [History] record.
  Future<void> softOn(GardenFeature feature) async {
    // Create a transient History record
    final history = History.forInsert(
        gardenFeatureId: feature.id, eventStart: DateTime.now());

    // Insert the new record to the database via DaoHistory
    await DaoHistory().insert(history);
  }

  /// Runs a [GardenFeature] for a specified [runTime], automatically scheduling
  /// an off action when the timer completes
  Future<void> runForTime({
    required GardenFeature feature,
    required String description,
    required Duration runTime,
  }) async {
    // Start the timer and call _timerCompleted when it finishes
    await TimerControl().startTimer(
      feature,
      description,
      runTime,
      (f) => _timerCompleted(feature),
    );

    // Immediately softOn the feature
    await softOn(feature);
  }

  /// Completes the timer for a [GardenFeature], turning it off
  /// and notifying any listeners.
  Future<void> _timerCompleted(GardenFeature feature) async {
    // Let EndPointBus know the timer is finished for the feature's
    //primary endpoint
    final id = feature.getPrimaryEndPoint();
    final endPoint = await DaoEndPoint().getById(id);
    EndPointBus.instance.timerFinished(endPoint!);

    // Soft off the feature
    await softOff(feature);
  }

  /// Marks a [GardenFeature] as turned off, completes its
  /// active [History] record,
  /// and updates the database accordingly.
  Future<void> softOff(GardenFeature feature) async {
    // Retrieve the currently running history entry if needed.
    // For example, you might fetch it from the database if you
    //don't track it in memory.
    final current = await _getLastActiveHistory(feature.id);
    if (current == null) {
      return; // No active history to complete
    }

    // Mark the history event complete
    current.markEventComplete();
    await DaoHistory().update(current);
  }

  /// Adds a [history] record to the local in-memory list or the DB.
  /// The original Java code called `feature.addHistory(history)`, but in Dart,
  /// we do an insert via [DaoHistory] directly if we want it persisted.
  Future<void> addHistory(GardenFeature feature, History history) async {
    history.gardenFeatureId = feature.id;
    await DaoHistory().insert(history);
  }

  /// Removes a [history] record from the DB.
  /// The original Java code also cleared the relationship in memory.
  Future<void> removeHistory(History history) async {
    // remove from DB
    await DaoHistory().delete(history.id);
  }

  /// Returns the last recorded [History] event for a given feature,
  /// or null if none.
  Future<History?> getLastEvent(int featureId) async {
    final records = await DaoHistory().getByGardenFeatureId(featureId);
    // The original code assumed the list is ordered by start time desc,
    // so we can return the first item if it exists.
    return records.isNotEmpty ? records.first : null;
  }

  /// Helper method to get the last inserted but unfinished [History]
  /// for a feature, if needed.
  Future<History?> _getLastActiveHistory(int featureId) async {
    // This is an example approach. You may store an "event_end" or
    //"duration" in the DB
    // that is null if the event is still active. Then query that record here.
    // If you rely on a special status or a column indicating active vs.
    // finished,
    // do the appropriate filtering. Otherwise, you may assume the first
    //record is active
    // if it’s missing an end time.
    final histories = await DaoHistory().getByGardenFeatureId(featureId);
    if (histories.isEmpty) {
      return null;
    }

    // The first record is presumably the most recent. Check if it's incomplete.
    final recent = histories.first;
    if (!recent.isComplete) {
      return recent;
    }
    return null;
  }
}
