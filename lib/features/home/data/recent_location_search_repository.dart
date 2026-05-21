import 'dart:convert';

import '../../recommendation/data/saved_location_storage.dart';
import '../models/recent_location_search.dart';

class RecentLocationSearchRepository {
  RecentLocationSearchRepository({
    SavedLocationStorage? storage,
  }) : _storage = storage ?? SavedLocationStorage();

  static const _storageKey = 'ppallae_recent_location_searches_v1';
  static const _maxItems = 10;

  final SavedLocationStorage _storage;

  Future<List<RecentLocationSearch>> load() async {
    final raw = await _storage.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      final items = decoded
          .whereType<Map>()
          .map(
            (item) => RecentLocationSearch.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return List.unmodifiable(items.take(_maxItems));
    } catch (_) {
      return const [];
    }
  }

  Future<List<RecentLocationSearch>> add(RecentLocationSearch item) async {
    final current = [...await load()];
    current.removeWhere((existing) {
      final sameQuery = existing.query.trim().toLowerCase() == item.query.trim().toLowerCase();
      final sameCoordinates =
          existing.latitude == item.latitude && existing.longitude == item.longitude;
      return sameQuery || sameCoordinates;
    });
    current.insert(0, item);
    final next = current.take(_maxItems).toList(growable: false);
    await _write(next);
    return next;
  }

  Future<List<RecentLocationSearch>> delete(String id) async {
    final current = [...await load()]..removeWhere((item) => item.id == id);
    await _write(current);
    return List.unmodifiable(current);
  }

  Future<List<RecentLocationSearch>> clear() async {
    await _write(const []);
    return const [];
  }

  Future<void> _write(List<RecentLocationSearch> items) async {
    await _storage.write(
      _storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
