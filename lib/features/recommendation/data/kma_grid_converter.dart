import 'dart:math';

class KmaGridPoint {
  const KmaGridPoint({
    required this.nx,
    required this.ny,
  });

  final int nx;
  final int ny;
}

class KmaGridConverter {
  const KmaGridConverter();

  KmaGridPoint fromLatLng({
    required double latitude,
    required double longitude,
  }) {
    const re = 6371.00877;
    const grid = 5.0;
    const slat1 = 30.0;
    const slat2 = 60.0;
    const olon = 126.0;
    const olat = 38.0;
    const xo = 43.0;
    const yo = 136.0;

    final degToRad = pi / 180.0;
    final reScaled = re / grid;
    final slat1Rad = slat1 * degToRad;
    final slat2Rad = slat2 * degToRad;
    final olonRad = olon * degToRad;
    final olatRad = olat * degToRad;

    var sn = tan(pi * 0.25 + slat2Rad * 0.5) / tan(pi * 0.25 + slat1Rad * 0.5);
    sn = log(cos(slat1Rad) / cos(slat2Rad)) / log(sn);
    var sf = tan(pi * 0.25 + slat1Rad * 0.5);
    sf = pow(sf, sn).toDouble() * cos(slat1Rad) / sn;
    var ro = tan(pi * 0.25 + olatRad * 0.5);
    ro = reScaled * sf / pow(ro, sn).toDouble();

    var ra = tan(pi * 0.25 + latitude * degToRad * 0.5);
    ra = reScaled * sf / pow(ra, sn).toDouble();
    var theta = longitude * degToRad - olonRad;
    if (theta > pi) {
      theta -= 2.0 * pi;
    }
    if (theta < -pi) {
      theta += 2.0 * pi;
    }
    theta *= sn;

    final nx = (ra * sin(theta) + xo + 0.5).floor();
    final ny = (ro - ra * cos(theta) + yo + 0.5).floor();
    return KmaGridPoint(nx: nx, ny: ny);
  }
}
