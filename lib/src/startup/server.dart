import 'dart:io';

import '../config.dart';
import '../http/web_server.dart';

Future<HttpServer> runServer(Config config) async =>
    await startWebServer(config);
