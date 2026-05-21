import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../recommendation/models/saved_location.dart';

class LocationSearchService {
  LocationSearchService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<LocationSelection>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
      queryParameters: {
        'q': trimmed,
        'format': 'jsonv2',
        'limit': '6',
        'accept-language': 'ko',
      },
    );

    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'ppallae-ppallae-dev/1.0',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('location search failed: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('location search parse failed');
    }

    return decoded.whereType<Map>().map((item) {
      final mapped = item.map((key, value) => MapEntry('$key', value));
      final displayName = '${mapped['display_name'] ?? trimmed}';
      final lat = double.tryParse('${mapped['lat'] ?? ''}') ?? 0;
      final lon = double.tryParse('${mapped['lon'] ?? ''}') ?? 0;
      final title = _titleFrom(displayName, fallback: trimmed);
      return LocationSelection.searched(
        label: title,
        address: displayName,
        latitude: lat,
        longitude: lon,
      );
    }).toList();
  }

  String _titleFrom(String displayName, {required String fallback}) {
    final parts = displayName.split(',');
    if (parts.isEmpty) {
      return fallback;
    }

    final title = parts.first.trim();
    return title.isEmpty ? fallback : title;
  }
}
