import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DataSourceScreen extends StatelessWidget {
  const DataSourceScreen({super.key});

  static const _sources = <_SourceInfo>[
    _SourceInfo(
      icon: Icons.cloud_outlined,
      category: '날씨 · 예보',
      provider: '기상청',
      detail: '단기예보(동네예보) / 초단기예보 · 초단기실황',
      note: '기온·습도·바람·강수·하늘 상태를 빨래지수 계산에 사용합니다.',
      url: 'https://www.weather.go.kr',
      linkLabel: '기상청 날씨누리',
    ),
    _SourceInfo(
      icon: Icons.air,
      category: '미세먼지',
      provider: '한국환경공단 에어코리아',
      detail: '시도별 실시간 측정정보 (PM10 / PM2.5)',
      note: '실외 건조 추천 여부 판단에 사용합니다.',
      url: 'https://www.airkorea.or.kr',
      linkLabel: '에어코리아',
    ),
    _SourceInfo(
      icon: Icons.map_outlined,
      category: '지도 · 장소',
      provider: '카카오',
      detail: '카카오맵 SDK · 카카오 로컬(장소 검색)',
      note: '지도 표시와 내 주변 빨래방 검색에 사용합니다.\n지도/장소 데이터의 저작권은 카카오에 있습니다.',
      url: 'https://www.kakaocorp.com',
      linkLabel: '카카오',
    ),
  ];

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('데이터 출처'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '이 앱은 아래 공공·민간 데이터를 활용합니다.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ..._sources.map((s) => _SourceCard(info: s, onOpen: _open)),
          const SizedBox(height: 8),
          _InfoCard(
            icon: Icons.lock_outline,
            title: '위치정보 처리 안내',
            body:
                '현재 위치(GPS) 좌표는 지역(행정구역) 변환과 지도 표시에 사용됩니다. '
                '좌표는 서버의 지역 변환 API에 전송되어 행정구역 코드와 기상청 격자 좌표(nx, ny)로 '
                '바뀐 뒤 응답을 받으며, 변환 후의 좌표값은 서버에 저장되지 않습니다. '
                '빨래지수 계산과 캐시에는 지역 코드와 격자 좌표만 사용됩니다.',
          ),
          _InfoCard(
            icon: Icons.info_outline,
            title: '정확도 면책',
            body:
                '빨래지수와 예상 건조 시간은 기상 예보를 바탕으로 한 추정치입니다. '
                '실제 날씨·환경에 따라 달라질 수 있으니 참고용으로만 활용해주세요.',
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '데이터 제공: 기상청 · 한국환경공단 · 카카오',
              style: TextStyle(fontSize: 12, color: Colors.black38),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SourceInfo {
  const _SourceInfo({
    required this.icon,
    required this.category,
    required this.provider,
    required this.detail,
    required this.note,
    required this.url,
    required this.linkLabel,
  });
  final IconData icon;
  final String category;
  final String provider;
  final String detail;
  final String note;
  final String url;
  final String linkLabel;
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.info, required this.onOpen});
  final _SourceInfo info;
  final Future<void> Function(String) onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(info.icon, color: const Color(0xFF3A7BD5)),
              const SizedBox(width: 8),
              Text(info.category,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 8),
          Text(info.provider,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(info.detail,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(info.note,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onOpen(info.url),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(info.linkLabel),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5A6677)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
