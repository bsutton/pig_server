import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'end_point_handler.dart';
import 'garden_bed_handler.dart';
import 'handle_booking.dart';
import 'handle_static.dart';
import 'lighting_handler.dart';
import 'overview_handler.dart';

Router buildRouter() {
  final router = Router()
    ..get('/', reject) // attempt to block spam.
    ..post('/booking', (Request request) async => handleBooking(request))
    ..post('/lighting/toggle', handleLightingToggle)
    ..post('/garden_bed/list', handleGardenBedList)
    ..post('/garden_bed/toggle', handleGardenBedToggle)
    ..post('/garden_bed/edit_data', handleGardenBedEditData)
    ..post('/garden_bed/save', handleGardenBedSave)
    ..post('/garden_bed/delete', handleGardenBedDelete)
    ..post('/lighting/list', handleLightingList)
    ..post('/end_point/list', handleEndPointList)
    ..post('/end_point/edit_data', handleEndPointEditData)
    ..post('/end_point/save', handleEndPointSave)
    ..post('/end_point/toggle', handleEndPointToggle)
    ..post('/end_point/delete', handleEndPointDelete)
    ..post('/overview', (Request request) async => handleOverview(request));
  return router;
}
