import 'package:shelf/shelf.dart';

import '../../config.dart';

/// Headers required to run a flutter wasm app from
/// our server.
const _flutterWasmBaseHeaders = <String, String>{
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers':
      'Origin, X-Requested-With, Content-Type, Accept, Authorization',
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Embedder-Policy': 'credentialless',
};

Map<String, String> _flutterWasmHeaders() {
  final allowWildcardOrigin = Config.cliDebug || (Config().debugMode ?? false);
  final headers = Map<String, String>.from(_flutterWasmBaseHeaders);
  if (allowWildcardOrigin) {
    headers['Access-Control-Allow-Origin'] = '*';
  }
  return headers;
}

// for OPTIONS (preflight) requests just add headers and an empty response
Response? _options(Request request) => (request.method == 'OPTIONS')
    ? Response.ok(null, headers: _flutterWasmHeaders())
    : null;

Response _cors(Response response) =>
    response.change(headers: _flutterWasmHeaders());

Middleware addWasmHeaders =
    createMiddleware(requestHandler: _options, responseHandler: _cors);
