import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../controllers/timer_control.dart';
import 'end_point_handler.dart';
import 'garden_bed_handler.dart';
import 'handle_static.dart';
import 'lighting_handler.dart';
import 'overview_handler.dart';

Router buildRouter() {
  final router = Router()
    ..get('/', reject) // attempt to block spam.
    ..post('/lighting/toggle', handleLightingToggle)
    ..post('/garden_bed/list', handleGardenBedList)
    ..post('/garden_bed/toggle', handleGardenBedToggle)
    ..post('/garden_bed/start_timer', handleGardenBedStartTimer)
    ..post('/garden_bed/stop_timer', handleGardenBedStopTimer)
    ..post('/garden_bed/edit_data', handleGardenBedEditData)
    ..post('/garden_bed/save', handleGardenBedSave)
    ..post('/garden_bed/delete', handleGardenBedDelete)
    ..post('/lighting/list', handleLightingList)
    ..post('/end_point/list', handleEndPointList)
    ..post('/end_point/edit_data', handleEndPointEditData)
    ..post('/end_point/save', handleEndPointSave)
    ..post('/end_point/toggle', handleEndPointToggle)
    ..post('/end_point/delete', handleEndPointDelete)
    ..post('/overview', (Request request) async => handleOverview(request))
    ..mount('/monitor', monitorHandler());

  return router;
}

// Future<Response?> monitor(Request request) async {

Handler monitorHandler() => webSocketHandler((WebSocketChannel socket, _) {
      print('websocket connected');
      TimerControl().monitor(socket.sink);
      socket.stream.listen((data) {
        print('WebSocket received: $data');
        socket.sink.add('Echo: $data');
      }, onDone: () {
        print('Closing monitor');
        TimerControl().stopMonitor(socket.sink);
        socket.sink.close();
      });
    });
