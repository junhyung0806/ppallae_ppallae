import 'package:flutter/material.dart';

import '../../data/location_result.dart';

class LocationDebugCard extends StatelessWidget {
  const LocationDebugCard({
    super.key,
    required this.result,
  });

  final LocationResult result;

  @override
  Widget build(BuildContext context) {
    final badge = _badgeData(result);
    final diagnostics = result.diagnostics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '개발용 진단 정보',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 10),
                _StatusBadge(
                  label: badge.label,
                  foregroundColor: badge.foregroundColor,
                  backgroundColor: badge.backgroundColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DebugLine(label: '표시값', value: result.displayText),
            _DebugLine(label: '단계', value: result.stage),
            _DebugLine(label: '에러코드', value: result.errorCode ?? '-'),
            _DebugLine(label: '원인', value: result.debugMessage ?? '-'),
            _DebugLine(
              label: '플랫폼',
              value: diagnostics['platform'] ?? '-',
            ),
            _DebugLine(
              label: 'provider',
              value: diagnostics['activeProvider'] ?? '-',
            ),
            _DebugLine(
              label: 'providerChain',
              value: diagnostics['providerChain'] ?? '-',
            ),
            _DebugLine(
              label: 'external api',
              value: diagnostics['externalApiEnabled'] ?? '-',
            ),
            _DebugLine(
              label: 'httpStatus',
              value: diagnostics['httpStatus'] ?? '-',
            ),
            _DebugLine(
              label: 'kakaoAttempted',
              value: diagnostics['kakaoAttempted'] ?? '-',
            ),
            _DebugLine(
              label: 'kakaoStatusCode',
              value: diagnostics['kakaoStatusCode'] ?? '-',
            ),
            _DebugLine(
              label: 'kakaoErrorMessage',
              value: diagnostics['kakaoErrorMessage'] ?? '-',
            ),
            _DebugLine(
              label: 'kakaoResponsePreview',
              value: diagnostics['kakaoResponsePreview'] ?? '-',
            ),
            _DebugLine(
              label: 'kakaoApiKeyPresent',
              value: diagnostics['kakaoApiKeyPresent'] ?? '-',
            ),
            _DebugLine(
              label: 'kakaoAuthHeaderName',
              value: diagnostics['kakaoAuthHeaderName'] ?? '-',
            ),
            _DebugLine(
              label: 'raw summary',
              value: diagnostics['rawResponseSummary'] ?? '-',
            ),
            _DebugLine(
              label: 'selectedRegionType',
              value: diagnostics['selectedRegionType'] ?? '-',
            ),
            _DebugLine(
              label: 'selectedRegion3Depth',
              value: diagnostics['selectedRegion3Depth'] ?? '-',
            ),
            _DebugLine(
              label: 'whetherBRegionFound',
              value: diagnostics['whetherBRegionFound'] ?? '-',
            ),
            _DebugLine(
              label: 'fallback',
              value: '${result.usedFallback}',
            ),
            _DebugLine(
              label: 'latitude',
              value: diagnostics['latitude'] ?? '-',
            ),
            _DebugLine(
              label: 'longitude',
              value: diagnostics['longitude'] ?? '-',
            ),
            _DebugLine(
              label: 'placemark 개수',
              value: diagnostics['placemarkCount'] ?? '-',
            ),
            _DebugLine(
              label: 'administrativeArea',
              value: diagnostics['administrativeArea'] ?? '-',
            ),
            _DebugLine(
              label: 'subAdministrativeArea',
              value: diagnostics['subAdministrativeArea'] ?? '-',
            ),
            _DebugLine(
              label: 'locality',
              value: diagnostics['locality'] ?? '-',
            ),
            _DebugLine(
              label: 'subLocality',
              value: diagnostics['subLocality'] ?? '-',
            ),
            _DebugLine(
              label: 'thoroughfare',
              value: diagnostics['thoroughfare'] ?? '-',
            ),
            if ((diagnostics['platformHint'] ?? '').isNotEmpty)
              _DebugLine(
                label: 'platform hint',
                value: diagnostics['platformHint']!,
              ),
          ],
        ),
      ),
    );
  }

  _BadgeData _badgeData(LocationResult result) {
    if ((result.errorCode ?? '').isNotEmpty) {
      return const _BadgeData(
        label: 'ERROR',
        foregroundColor: Color(0xFF9F1D1D),
        backgroundColor: Color(0xFFFFE7E8),
      );
    }

    if (result.usedFallback) {
      return const _BadgeData(
        label: 'FALLBACK',
        foregroundColor: Color(0xFF8A4B00),
        backgroundColor: Color(0xFFFFF0D9),
      );
    }

    return const _BadgeData(
      label: 'SUCCESS',
      foregroundColor: Color(0xFF16643A),
      backgroundColor: Color(0xFFE5F7EE),
    );
  }
}

class _DebugLine extends StatelessWidget {
  const _DebugLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF102033),
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF314154),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}

class _BadgeData {
  const _BadgeData({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
}
