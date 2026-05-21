import '../../recommendation/models/saved_location.dart';

class RecentLocationSearch {
  const RecentLocationSearch({
    required this.id,
    required this.query,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
  });

  factory RecentLocationSearch.fromJson(Map<String, dynamic> json) {
    return RecentLocationSearch(
      id: '${json['id'] ?? ''}',
      query: '${json['query'] ?? ''}',
      latitude: (json['lat'] as num?)?.toDouble() ?? 0,
      longitude: (json['lng'] as num?)?.toDouble() ?? 0,
      address: '${json['address'] ?? ''}',
      timestamp: DateTime.tryParse('${json['timestamp'] ?? ''}') ?? DateTime.now(),
    );
  }

  factory RecentLocationSearch.fromSelection(
    LocationSelection selection, {
    required String query,
  }) {
    final now = DateTime.now();
    return RecentLocationSearch(
      id: 'recent_${now.microsecondsSinceEpoch}',
      query: query.trim().isEmpty ? selection.label : query.trim(),
      latitude: selection.latitude ?? 0,
      longitude: selection.longitude ?? 0,
      address: selection.address,
      timestamp: now,
    );
  }

  final String id;
  final String query;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'lat': latitude,
      'lng': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String get label {
    final parts = address.split(',');
    final first = parts.isEmpty ? query : parts.first.trim();
    return first.isEmpty ? query : first;
  }

  String get subtitle {
    final normalized = address.trim();
    if (normalized.isEmpty) {
      return query;
    }
    return normalized;
  }

  LocationSelection toLocationSelection() {
    return LocationSelection.searched(
      id: id,
      label: label,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
