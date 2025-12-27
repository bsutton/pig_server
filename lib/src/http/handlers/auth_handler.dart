import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../security/auth_service.dart';

Future<Response> handleAuthChallenge(Request request) async {
  try {
    final challenge = AuthService.instance.createChallenge();
    return Response.ok(
      jsonEncode(challenge.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

Future<Response> handleAuthLogin(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>? ?? {};
    final nonce = body['nonce'] as String?;
    final responseHex = body['response'] as String?;

    if (nonce == null || responseHex == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing nonce or response'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final token = AuthService.instance.verifyLogin(
      nonce: nonce,
      responseHex: responseHex,
    );
    if (token == null) {
      return Response.forbidden(
        jsonEncode({'error': 'Invalid credentials'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({
        'token': token.value,
        'expiresIn': token.expiresAt.difference(DateTime.now()).inSeconds,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
