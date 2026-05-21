class Laundromat {
  const Laundromat({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
}

class SelectedLaundromat {
  const SelectedLaundromat({
    required this.laundromat,
    required this.distanceMeters,
  });

  final Laundromat laundromat;
  final double distanceMeters;

  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()}m';
    }

    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  String get walkingTimeLabel {
    final minutes = (distanceMeters / 75).clamp(1, 99).round();
    return '도보 $minutes분';
  }
}
