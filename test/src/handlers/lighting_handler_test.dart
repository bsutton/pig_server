import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('Lighting HTTP Endpoint Tests', () {
    const baseUrl = 'http://localhost:1080/lighting';

    test('POST: List all lights', () async {
      // Act
      final response = await http.post(
        Uri.parse('$baseUrl/list'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );

      // Assert
      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body, isA<Map<String, dynamic>>());
      expect(body['lights'], isA<List<Map<String, dynamic>>>());
      for (final light in (body['lights']) as List<Map<String, dynamic>>) {
        expect(light['id'], isA<int>());
        expect(light['name'], isA<String>());
        expect(light['isOn'], isA<bool>());
        expect(light['lastOnDate'], anyOf(isA<String>(), isNull));
        expect(light['timerRunning'], isA<bool>());
        expect(light['timerRemainingSeconds'], isA<int>());
      }
    });

    test('POST: Toggle light ON with timer', () async {
      // Arrange
      const lightId = 1;
      const durationSeconds = 1800; // 30 minutes
      final requestBody = {
        'lightId': lightId,
        'turnOn': true,
        'durationSeconds': durationSeconds,
      };

      // Act
      final response = await http.post(
        Uri.parse('$baseUrl/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Assert
      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['result'], equals('OK'));
      expect(body['timerStarted'], isTrue);
      expect(body['timerRemainingSeconds'], equals(durationSeconds));
    });

    test('POST: Toggle light ON without timer', () async {
      // Arrange
      const lightId = 1;
      final requestBody = {
        'lightId': lightId,
        'turnOn': true,
      };

      // Act
      final response = await http.post(
        Uri.parse('$baseUrl/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Assert
      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['result'], equals('OK'));
      expect(body['timerStarted'], isFalse);
    });

    test('POST: Toggle light OFF', () async {
      // Arrange
      const lightId = 1;
      final requestBody = {
        'lightId': lightId,
        'turnOn': false,
      };

      // Act
      final response = await http.post(
        Uri.parse('$baseUrl/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Assert
      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['result'], equals('OK'));
    });

    test('POST: Toggle non-existent light', () async {
      // Arrange
      const lightId = 9999; // Assuming this ID doesn't exist
      final requestBody = {
        'lightId': lightId,
        'turnOn': true,
      };

      // Act
      final response = await http.post(
        Uri.parse('$baseUrl/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Assert
      expect(response.statusCode, equals(404));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['error'], equals('Light not found'));
    });

    test('POST: Toggle with missing parameters', () async {
      // Arrange
      final requestBody = <String, dynamic>{
        // Missing lightId and turnOn
      };

      // Act
      final response = await http.post(
        Uri.parse('$baseUrl/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Assert
      expect(response.statusCode, equals(400));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['error'], contains('Missing lightId or turnOn'));
    });
  });
}
