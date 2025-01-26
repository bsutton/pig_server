import '../config.dart';
import '../http/web_server.dart';

Future<void> runServer(Config config) async {


  await startWebServer(config);
}
