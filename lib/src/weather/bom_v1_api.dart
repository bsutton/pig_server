import 'dart:convert';
import 'dart:io';

import '../logger.dart';

class BomLocation {
  final String id;

  final String name;

  final String state;

  final String geohash;

  BomLocation({
    required this.id,
    required this.name,
    required this.state,
    required this.geohash,
  });

  factory BomLocation.fromFeature(Map<String, dynamic> featureJson) {
    final props = featureJson['properties'] as Map<String, dynamic>;
    return BomLocation(
      id: props['id'].toString(),
      name: props['name']?.toString() ?? '',
      state: props['state']?.toString() ?? '',
      geohash: props['geohash']?.toString() ?? '',
    );
  }

  factory BomLocation.fromSearchData(Map<String, dynamic> data) => BomLocation(
        id: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        state: data['state']?.toString() ?? '',
        geohash: data['geohash']?.toString() ?? '',
      );

  factory BomLocation.fromLookup(Map<String, dynamic> lookupJson) {
    final data = lookupJson['data'] as Map<String, dynamic>;
    return BomLocation(
      id: data['id'].toString(),
      name: data['name']?.toString() ?? '',
      state: data['state']?.toString() ?? '',
      geohash: data['geohash']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'state': state,
        'geohash': geohash,
      };
}

class BomV1Api {
  static const _base = 'https://api.weather.bom.gov.au/v1/';

  String _normalizeGeohash(String geohash) {
    final trimmed = geohash.trim();
    if (trimmed.length <= 6) {
      return trimmed;
    }
    return trimmed.substring(0, 6);
  }

  Future<List<BomLocation>> searchLocations(String query) async {
    final uri = Uri.parse(
      '${_base}locations?search=${Uri.encodeComponent(query)}',
    );
    final json = await _getJson(uri);
    final results = json['data'] as List<dynamic>? ?? [];
    return results
        .map((e) => BomLocation.fromSearchData(e as Map<String, dynamic>))
        .toList();
  }

  Future<BomLocation?> lookupLocation(String geohash) async {
    final uri = Uri.parse('${_base}locations/lookup?geohash=$geohash');
    final json = await _getJson(uri);
    return BomLocation.fromLookup(json);
  }

  Future<Map<String, dynamic>?> observations(String geohash) async {
    final normalized = _normalizeGeohash(geohash);
    final uri = Uri.parse('${_base}locations/$normalized/observations');
    final json = await _getJson(uri);
    return json['data'] as Map<String, dynamic>?;
  }

  Future<bool> hasData(String geohash) async {
    final obs = await observations(geohash);
    if (obs != null && obs.isNotEmpty) {
      return true;
    }
    final daily = await forecastsDaily(geohash);
    return daily.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> forecastsDaily(String geohash) async {
    final normalized = _normalizeGeohash(geohash);
    final uri = Uri.parse('${_base}locations/$normalized/forecasts/daily');
    final json = await _getJson(uri);
    return (json['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> forecastRain(
      {required String geohash, required String period}) async {
    final normalized = _normalizeGeohash(geohash);
    final uri = Uri.parse('${_base}rain?geohash=$normalized&period=$period');
    final json = await _getJson(uri);
    return json['data'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'pigation-server/1.0');
      final response = await request.close();
      if (response.statusCode == 404) {
        qlog('BOM request returned 404 for $uri');
        return <String, dynamic>{};
      }
      if (response.statusCode >= 400) {
        final body = await response.transform(utf8.decoder).join();
        throw HttpException('''
BOM request failed: ${response.statusCode} ${response.reasonPhrase} $body''');
      }
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      qlog('BOM request failed: $e');
      rethrow;
    } finally {
      client.close(force: true);
    }
  }
}
