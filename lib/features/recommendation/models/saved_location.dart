import 'dart:convert';

import 'current_location_summary.dart';

enum LocationSourceType {
  current(label: '현재 위치'),
  saved(label: '저장 위치'),
  search(label: '검색 위치');

  const LocationSourceType({
    required this.label,
  });

  final String label;
}

class SavedLocation {
  const SavedLocation({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  factory SavedLocation.create({
    required String label,
    required double latitude,
    required double longitude,
    required String address,
    bool isPinned = false,
  }) {
    final now = DateTime.now();
    return SavedLocation(
      id: 'saved_${now.microsecondsSinceEpoch}',
      label: label,
      latitude: latitude,
      longitude: longitude,
      address: address,
      createdAt: now,
      updatedAt: now,
      isPinned: isPinned,
    );
  }

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: '${json['id'] ?? ''}',
      label: '${json['label'] ?? ''}',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      address: '${json['address'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}') ?? DateTime.now(),
      isPinned: json['isPinned'] == true,
    );
  }

  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  SavedLocation copyWith({
    String? id,
    String? label,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

class LocationSelection {
  const LocationSelection({
    required this.id,
    required this.sourceType,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory LocationSelection.current(CurrentLocationSummary current) {
    return LocationSelection(
      id: 'current',
      sourceType: LocationSourceType.current,
      label: '현재 위치',
      address: current.displayText,
      latitude: current.latitude,
      longitude: current.longitude,
    );
  }

  factory LocationSelection.saved(SavedLocation saved) {
    return LocationSelection(
      id: saved.id,
      sourceType: LocationSourceType.saved,
      label: saved.label,
      address: saved.address,
      latitude: saved.latitude,
      longitude: saved.longitude,
    );
  }

  factory LocationSelection.searched({
    String? id,
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    return LocationSelection(
      id: id ?? 'search_${DateTime.now().microsecondsSinceEpoch}',
      sourceType: LocationSourceType.search,
      label: label,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  final String id;
  final LocationSourceType sourceType;
  final String label;
  final String address;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get chipLabel => sourceType == LocationSourceType.current ? '현재 위치' : label;

  String get sourceLabel => sourceType.label;

  String get summaryLabel {
    if (sourceType == LocationSourceType.current) {
      return address;
    }
    return '$label · $address';
  }

  SavedLocation toSavedLocation({
    required String savedLabel,
    bool isPinned = false,
  }) {
    return SavedLocation.create(
      label: savedLabel,
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
      address: address,
      isPinned: isPinned,
    );
  }
}
