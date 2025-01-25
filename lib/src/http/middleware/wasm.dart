import 'package:shelf/shelf.dart';

/// Headers required to run a flutter wasm app from
/// our server.
final Map<String, String> _flutterWasmHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST',
  'Access-Control-Allow-Headers':
      'Origin, X-Requested-With, Content-Type, Accept',
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Embedder-Policy': 'credentialless',
};

// for OPTIONS (preflight) requests just add headers and an empty response
Response? _options(Request request) => (request.method == 'OPTIONS')
    ? Response.ok(null, headers: _flutterWasmHeaders)
    : null;

Response _cors(Response response) =>
    response.change(headers: _flutterWasmHeaders);

Middleware addWasmHeaders =
    createMiddleware(requestHandler: _options, responseHandler: _cors);
