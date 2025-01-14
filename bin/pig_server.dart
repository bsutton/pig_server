#! /usr/bin/env dcli
// ignore_for_file: avoid_types_on_closure_parameters

import 'dart:async';
import 'dart:io';

import 'package:cron/cron.dart';
import 'package:dcli/dcli.dart';
import 'package:dnsolve/dnsolve.dart';
import 'package:pig_server/src/config.dart';
import 'package:pig_server/src/database/factory/cli_database_factory.dart';
import 'package:pig_server/src/database/management/database_helper.dart';
import 'package:pig_server/src/database/management/local_backup_provider.dart';
import 'package:pig_server/src/database/versions/asset_script_source.dart';
import 'package:pig_server/src/handlers/router.dart';
import 'package:pig_server/src/logger.dart';
import 'package:pig_server/src/mailer.dart';
import 'package:pig_server/src/pi/gpio_manager.dart';
import 'package:pig_server/src/weather/bureaus/weather_bureaus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_letsencrypt/shelf_letsencrypt.dart';
import 'package:shelf_rate_limiter/shelf_rate_limiter.dart';

enum CertificateMode { staging, production }

late HttpServer server;
late HttpServer secureServer;

/// Simple web server that can serve stastic content and email
/// a booking.
void main() async {
  final config = Config();
  final pathToStaticContent = config.pathToStaticContent;
  await _checkConfiguration(pathToStaticContent);

  await _checkFQDNResolved(config.fqdn);

  final domain = Domain(name: config.fqdn, email: config.domainEmail);

  await _initDb();

  WeatherBureaus.initialize();

  await _initPins();

  final letsEncrypt = build(
      mode: Config().production
          ? CertificateMode.production
          : CertificateMode.staging);

  if (Config().useHttps) {
    await _startHttpsServer(letsEncrypt, domain);
    await _startRenewalService(letsEncrypt, domain);
  } else {
    await _startWebServer();
  }

  await _sendTestEmail();
}

Future<void> _initPins() async {
  // Provision pins at application startup.
  await GpioManager().provisionPins();
}

// TODO(bsutton): call shutdown as the web server stops.
void shutdown() {
  qlog('Irrigation Manager is shutting down.');
  // stop all GPIO activity/threads by shutting down the GPIO controller
  // (this method will forcefully shutdown all GPIO monitoring threads and
  // scheduled tasks)
  GpioManager().shutdown();
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
      .addHandler(router.call);

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
      .addHandler(router.call);

  final servers = await letsEncrypt.startServer(
    handler,
    [domain],
  );

  server = servers[0]; // HTTP Server.
  secureServer = servers[1]; // HTTPS Server.

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
  final certificatesDirectory = config.letsEncryptLive;

  // The Certificate handler, storing at `certificatesDirectory`.
  final certificatesHandler =
      CertificatesHandlerIO(Directory(certificatesDirectory));

  final letsEncrypt = LetsEncrypt(certificatesHandler,
      port: config.httpPort,
      securePort: config.httpsPort,
      bindingAddress: config.bindingAddress,
      selfTest: false,
      production: mode == CertificateMode.production)
    ..minCertificateValidityTime = const Duration(days: 10);

  return letsEncrypt;
}

Future<void> _checkConfiguration(String pathToStaticContent) async {
  qlog(green('PiGation Server'));
  qlog(blue('Loading config.yaml from ${truepath(Config().loadedFrom)}'));

  qlog(blue('Starting web server'));
}

Future<void> _sendTestEmail() async {
  qlog('Sending test email to bsutton@onepub.dev');
  final result = await sendEmail(
      from: 'startup@onepub.dev',
      to: 'bsutton@onepub.dev',
      subject: 'PiGation',
      body: 'The PiGation Server has been restarted');

  if (!result) {
    qlogerr(red(
        '''Failed to send startup email: check the configuration at ${Config().loadedFrom}'''));
    exit(33);
  }
}

Future<void> _initDb() async {
  final backupProvider = LocalBackupProvider(CliDatabaseFactory());
  try {
    await DatabaseHelper().initDatabase(
        src: AssetScriptSource(),
        backupProvider: backupProvider,
        backup: true,
        databaseFactory: CliDatabaseFactory());
    print('Database located at: ${await backupProvider.databasePath}');
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
