import 'dart:async';
import 'dart:io';

import 'package:cron/cron.dart';
import 'package:dcli/dcli.dart';
import 'package:dnsolve/dnsolve.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_letsencrypt/shelf_letsencrypt.dart';
import 'package:shelf_rate_limiter/shelf_rate_limiter.dart';

import '../config.dart';
import '../database/factory/cli_database_factory.dart';
import '../database/management/database_helper.dart';
import '../database/management/local_backup_provider.dart';
import '../database/versions/resource_script_source.dart';
import '../logger.dart';
import '../pi/gpio_manager.dart';
import '../weather/bureaus/weather_bureaus.dart';
import 'handlers/router.dart';
import 'middleware/wasm.dart';

enum CertificateMode { staging, production }

late HttpServer server;
late HttpServer secureServer;

Future<void> startWebServer(Config config) async {
  final pathToStaticContent = config.pathToStaticContent;
  await _checkConfiguration(pathToStaticContent!);

  await _checkFQDNResolved(config.fqdn!);

  final domain = Domain(name: config.fqdn!, email: config.domainEmail!);

  await _initDb();

  WeatherBureaus.initialize();

  await _initPins();

  if (Config().useHttps) {
    final letsEncrypt = build(
        mode: Config().production!
            ? CertificateMode.production
            : CertificateMode.staging);
    await _startHttpsServer(letsEncrypt, domain);
    await _startRenewalService(letsEncrypt, domain);
  } else {
    await _startWebServer();
  }
}

Future<void> _initPins() async {
  // Provision pins at application startup.
  await GpioManager().provisionPins();
}

Future<void> _checkFQDNResolved(String fqdn) async {
  final dnsolve = DNSolve();
  final response = await dnsolve.lookup(fqdn);
  if (response.answer?.records != null) {
    for (final record in response.answer!.records!) {
      qlog(record.toBind);
    }
  }
}

Future<void> _startRenewalService(
    LetsEncrypt letsEncrypt, Domain domain) async {
  final httpPort = Config().httpPort;
  Cron().schedule(
      Schedule(hours: '*/1'), // every hour
      () => refreshIfRequired(httpPort, letsEncrypt, domain));
}

Future<void> refreshIfRequired(
    int httpPort, LetsEncrypt letsEncrypt, Domain domain) async {
  qlog(blue('Checking if cert needs to be renewed'));
  final result =
      await letsEncrypt.checkCertificate(domain, requestCertificate: true);

  if (result.isOkRefreshed) {
    qlog(blue('certificate was renewed - restarting service'));
    // restart the servers.
    await Future.wait<void>([server.close(), secureServer.close()]);
    await _startHttpsServer(letsEncrypt, domain);
    qlog(blue('services restarted'));
  } else {
    qlog(blue('Renewal not required'));
  }
}

Future<void> _startWebServer() async {
  final router = buildRouter();

  final handler = const Pipeline()
      .addMiddleware(logRequests(logger: _log))
      .addMiddleware(rateLimiter.rateLimiter())
      .addMiddleware(addWasmHeaders)
      .addHandler(router.call);
  // .addHandler(router.call);

  final server = await serve(
    handler,
    Config().bindingAddress,
    Config().httpPort,
  );
  qlog('Serving at http://${server.address.host}:${server.port}');
}

Future<void> _startHttpsServer(LetsEncrypt letsEncrypt, Domain domain) async {
  final router = buildRouter();

  final redirectToHttps = createMiddleware(requestHandler: _redirectToHttps);

  final handler = const Pipeline()
      .addMiddleware(redirectToHttps)
      .addMiddleware(logRequests(logger: _log))
      .addMiddleware(rateLimiter.rateLimiter())
      .addMiddleware(addWasmHeaders)
      .addHandler(router.call);

  final servers = await letsEncrypt.startServer(
    handler,
    [domain],
  );

  server = servers.http;
  secureServer = servers.https;

  // Enable gzip:
  server.autoCompress = true;
  secureServer.autoCompress = true;

  qlog('Serving at http://${server.address.host}:${server.port}');
  qlog('Serving at https://${secureServer.address.host}:${secureServer.port}');
}

/// Redirect all http traffic to https.
/// This shouldn't interfere with lets encrypt as ti hooks
/// into the  pipeline before this middleware is called.
FutureOr<Response?> _redirectToHttps(Request request) async {
  if (request.requestedUri.scheme == 'http') {
    final headers = <String, String>{
      'location':
          '''${request.requestedUri.replace(scheme: "https", port: Config().httpsPort)}'''
    };
    return Response(302, headers: headers);
  }
  return null;
}

void _log(String message, bool isError) {
  qlog(orange(message));
}

// [fqdn] is the fqdn for the HTTPS certificate
LetsEncrypt build({CertificateMode mode = CertificateMode.staging}) {
  final config = Config();
  final certificatesDirectory = config.pathToLetsEncryptLive!;

  // The Certificate handler, storing at `certificatesDirectory`.
  final certificatesHandler =
      CertificatesHandlerIO(Directory(certificatesDirectory));

  final letsEncrypt = LetsEncrypt(certificatesHandler,
      port: config.httpPort,
      securePort: config.httpsPort,
      bindingAddress: config.bindingAddress,
      production: mode == CertificateMode.production)
    ..minCertificateValidityTime = const Duration(days: 10);

  return letsEncrypt;
}

Future<void> _checkConfiguration(String pathToStaticContent) async {
  qlog(green('PiGation Server'));
  final config = Config();

  qlog(blue('Loading config.yaml from ${truepath(config.loadedFrom)}'));

  qlog(blue(buildStartingMessage(config)));
}

String buildStartingMessage(Config config) {
  final sb = StringBuffer()..write('Starting web server endpoint: ');

  if (config.useHttps) {
    sb.write('https://${config.bindingAddress}:${config.httpsPort}');
  } else {
    sb.write('https://${config.bindingAddress}:${config.httpPort}');
  }

  return sb.toString();
}

Future<void> _initDb() async {
  final backupProvider = LocalBackupProvider(CliDatabaseFactory());
  try {
    await DatabaseHelper().initDatabase(
        src: ResourceScriptSource(),
        backupProvider: backupProvider,
        backup: true,
        databaseFactory: CliDatabaseFactory());
    print('Database located at: ${backupProvider.databasePath}');
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    qlogerr('Db open failed. Try rebooting your phone or restore the db $e');
    rethrow;
  }
}

/// define a memory backed ratelimiter to 10 requests per minute.
final memoryStorage = MemStorage();
final rateLimiter = ShelfRateLimiter(
    storage: memoryStorage,
    duration: const Duration(seconds: 60),
    maxRequests: 100);
