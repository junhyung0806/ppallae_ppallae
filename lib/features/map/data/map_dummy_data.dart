import 'package:google_maps_flutter/google_maps_flutter.dart';

class LaundryPlace {
  const LaundryPlace({
    required this.id,
    required this.name,
    required this.distanceLabel,
    required this.position,
  });

  final String id;
  final String name;
  final String distanceLabel;
  final LatLng position;
}

const dummyCurrentPosition = LatLng(37.5447, 127.0557);

List<LaundryPlace> buildNearbyLaundryPlaces(LatLng center) {
  return [
    LaundryPlace(
      id: 'laundry_1',
      name: '성수 스마트 빨래방',
      distanceLabel: '도보 4분',
      position: LatLng(center.latitude + 0.0011, center.longitude + 0.0022),
    ),
    LaundryPlace(
      id: 'laundry_2',
      name: '서울숲 코인워시',
      distanceLabel: '도보 7분',
      position: LatLng(center.latitude - 0.0013, center.longitude - 0.0018),
    ),
    LaundryPlace(
      id: 'laundry_3',
      name: '뚝섬 드라이 라운지',
      distanceLabel: '도보 10분',
      position: LatLng(center.latitude + 0.0018, center.longitude - 0.0024),
    ),
  ];
}
