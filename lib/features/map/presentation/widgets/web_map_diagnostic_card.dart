import 'package:flutter/material.dart';

import '../../data/web_map_diagnostic.dart';

class WebMapDiagnosticCard extends StatelessWidget {
  const WebMapDiagnosticCard({
    super.key,
    required this.diagnostic,
  });

  final WebMapDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final details = diagnostic.details;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '웹 지도 진단',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 10),
                _Badge(
                  label: diagnostic.isReady ? 'READY' : 'CHECK',
                  color: diagnostic.isReady
                      ? const Color(0xFFE5F7EE)
                      : const Color(0xFFFFE7E8),
                  textColor: diagnostic.isReady
                      ? const Color(0xFF16643A)
                      : const Color(0xFF9F1D1D),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Line(label: '단계', value: diagnostic.stage),
            _Line(label: '에러코드', value: diagnostic.code ?? '-'),
            _Line(label: '메시지', value: diagnostic.message),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                '개발용 상세 로그',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              children: [
                ...details.entries.map(
                  (entry) => _Line(label: entry.key, value: entry.value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
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
                color: Color(0xFF102033),
                fontWeight: FontWeight.w800,
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

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
