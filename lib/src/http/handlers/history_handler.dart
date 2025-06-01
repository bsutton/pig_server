// lib/src/handler/history_handler.dart

import 'dart:convert';

import 'package:pig_common/pig_common.dart';
import 'package:shelf/shelf.dart';

import '../../database/dao/dao_garden_bed.dart';
import '../../database/dao/dao_history.dart';

/// Handle POST /history/list
/// Returns: { "history": [ { …HistoryData JSON… }, … ] }
Future<Response> handleHistoryList(Request request) async {
  try {
    final historyDao = DaoHistory();
    final bedDao = DaoGardenBed();

    final allHistory = await historyDao.getLast7Days();
    final transferList = <HistoryData>[];

    for (final hist in allHistory) {
      // Lookup the garden bed name (or feature name) by ID
      final bed = await bedDao.getById(hist.gardenFeatureId);
      final name = bed?.name ?? 'Unknown Feature (${hist.gardenFeatureId})';

      // Build our HistoryData DTO
      final dto = HistoryData.fromHistory(
        hist,
        featureName: name,
      );
      transferList.add(dto);
    }

    // Convert each DTO → JSON map via toJson()
    final jsonList = transferList.map((dto) => dto.toJson()).toList();
    final body = jsonEncode({'history': jsonList});
    return Response.ok(body, headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
