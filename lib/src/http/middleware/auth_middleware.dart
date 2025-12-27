import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../security/auth_service.dart';

Middleware authMiddleware() => (innerHandler) => (request) async {
      if (_isPublic(request)) {
        return innerHandler(request);
      }
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.unauthorized(
          jsonEncode({'error': 'Missing authorization token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      final token = authHeader.substring('Bearer '.length).trim();
      if (!AuthService.instance.isValidToken(token)) {
        return Response.forbidden(
          jsonEncode({'error': 'Invalid or expired token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      return innerHandler(request);
    };

bool _isPublic(Request request) {
  final path = request.url.path;
  if (request.method == 'OPTIONS') {
    return true;
  }
  if (request.method == 'GET' || request.method == 'HEAD') {
    return true;
  }
  if (path.startsWith('auth/')) {
    return true;
  }
  return false;
}
