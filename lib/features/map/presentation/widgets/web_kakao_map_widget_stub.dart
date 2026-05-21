import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/laundromat.dart';
import '../../data/web_map_diagnostic.dart';

class WebKakaoMapWidget extends StatelessWidget {
  const WebKakaoMapWidget({
    super.key,
    required this.currentPosition,
    required this.places,
    required this.onPlaceSelected,
    required this.onDiagnosticChanged,
    this.onPointerHoverChanged,
  });

  final LatLng currentPosition;
  final List<SelectedLaundromat> places;
  final ValueChanged<SelectedLaundromat> onPlaceSelected;
  final ValueChanged<WebMapDiagnostic> onDiagnosticChanged;
  final ValueChanged<bool>? onPointerHoverChanged;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
