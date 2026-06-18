import 'package:flutter/material.dart';

/// 빨래빨래의 점수/등급 기준 + 계산 알고리즘 설명.
/// 정보 탭에서 '데이터 출처'와 같은 형식의 화면.
class ScoreCriteriaScreen extends StatelessWidget {
  const ScoreCriteriaScreen({super.key});

  static const _grades = <_GradeInfo>[
    _GradeInfo(
      range: '100 ~ 85',
      label: '최고',
      color: Color(0xFF5BA3D3),
      icon: 'assets/icons/256/grade_excellent.png',
      desc: '맑고 건조하고 바람 좋음. 두꺼운 옷도 잘 마름.',
    ),
    _GradeInfo(
      range: '84 ~ 70',
      label: '좋음',
      color: Color(0xFF5DAB6C),
      icon: 'assets/icons/256/grade_good.png',
      desc: '대체로 좋은 조건. 일반 빨래 추천.',
    ),
    _GradeInfo(
      range: '69 ~ 50',
      label: '보통',
      color: Color(0xFFE5B946),
      icon: 'assets/icons/256/grade_normal.png',
      desc: '얇은 옷 위주로만 권장. 두꺼운 옷은 다음 기회에.',
    ),
    _GradeInfo(
      range: '49 ~ 30',
      label: '나쁨',
      color: Color(0xFFE89464),
      icon: 'assets/icons/256/grade_bad.png',
      desc: '습도가 높거나 바람이 약해요. 다음 날을 노리는 게 좋아요.',
    ),
    _GradeInfo(
      range: '29 ~ 0',
      label: '최악',
      color: Color(0xFFD17878),
      icon: 'assets/icons/256/grade_very_bad.png',
      desc: '비/눈 또는 매우 높은 습도. 오늘은 빨래를 미루는 걸 추천해요.',
    ),
  ];

  static const _factors = <_FactorInfo>[
    _FactorInfo(
      icon: Icons.water_drop_outlined,
      title: '기온 × 습도 — VPD (가장 큰 영향)',
      body: '기온이 높을수록, 습도가 낮을수록 공기가 더 많은 수분을 빨아들일 수 있어요(VPD가 커요). '
          '예: 25°C·습도 40% > 18°C·습도 70%. 빨래가 마르는 가장 근본적인 힘.',
    ),
    _FactorInfo(
      icon: Icons.air,
      title: '바람',
      body: '약 1~4 m/s가 최적. 너무 약하면 빨래 주변 공기가 정체되어 잘 안 마르고, '
          '너무 강하면 빨래가 날아갈 위험. 7 m/s 이상부터는 감점됩니다.',
    ),
    _FactorInfo(
      icon: Icons.wb_sunny_outlined,
      title: '햇빛 (낮·하늘 상태)',
      body: '낮 시간대의 맑음 > 부분 흐림 > 흐림 순. 햇빛은 살균/탈취 효과도 있어요. '
          '밤 시간대는 일조 효과 0 (대신 VPD/바람/장소가 점수 결정).',
    ),
    _FactorInfo(
      icon: Icons.umbrella_outlined,
      title: '강수 (가장 큰 감점)',
      body: '비/눈/진눈깨비가 예보된 시간은 건조력 0에 가깝게 떨어집니다. '
          '실외/베란다는 직접 영향이 크고, 실내도 외기 습도 상승으로 점수가 떨어져요.',
    ),
    _FactorInfo(
      icon: Icons.home_outlined,
      title: '건조 장소',
      body: '실외 > 베란다 > 실내 순으로 기본 건조력이 다릅니다. '
          '실외는 바람·햇빛 효과가 그대로, 실내는 바람/햇빛 영향이 크게 줄어 VPD에 더 의존합니다.',
    ),
    _FactorInfo(
      icon: Icons.blur_on,
      title: '미세먼지 (실외·베란다)',
      body: 'PM10·PM2.5 "나쁨" 이상이면 실외 점수에서 추가 감점. '
          '실내 건조에는 영향이 거의 없습니다.',
    ),
  ];

  // 빨래 양은 사용자 노출 없이 항상 "보통" 기준으로 백엔드에 전송되므로,
  // 알고리즘 설명에서도 양에 따른 차이는 다루지 않는다 ([kFixedLaundryAmount] 참고).

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('빨래빨래 기준'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '빨래지수가 어떻게 계산되는지, 등급은 어떤 의미인지 안내합니다.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 16),

          // ── 등급 5단계 ──
          const _SectionTitle('등급 5단계'),
          ..._grades.map((g) => _GradeCard(info: g)),
          const SizedBox(height: 8),

          // ── 계산 알고리즘 ──
          const _SectionTitle('계산 알고리즘'),
          const _InfoCard(
            icon: Icons.functions,
            title: '점수 산출 방식 — 누적 건조력 모델',
            body: '기상청 시간별 예보와 에어코리아 미세먼지를 바탕으로 '
                '시간당 "건조력(dry power)"을 계산합니다.\n\n'
                '시간당 건조력 = VPD × 바람 × 햇빛 × 장소 × 강수\n\n'
                '12시간 동안의 건조력을 누적해서 "빨래가 마르는 데 필요한 양"과 비교하여 '
                '0~100점으로 환산합니다. 즉 한 시점의 날씨가 아니라 '
                '그 시각에 빨래를 널면 이후 12시간 동안 얼마나 잘 마를지를 본 점수예요.',
          ),
          ..._factors.map((f) => _FactorCard(info: f)),
          const SizedBox(height: 8),

          // ── 추천 시간 ──
          const _SectionTitle('추천 시간 선정'),
          const _InfoCard(
            icon: Icons.schedule,
            title: '30시간 horizon · 최적 시작 시점 1개 선택',
            body: '지금부터 향후 30시간 동안 1시간 간격으로 빨래 시작 후보를 만들어, '
                '각 후보마다 (세탁기 45분 후) 빨래를 너는 시점부터 12시간의 누적 건조력을 산출합니다. '
                '점수가 가장 높은 후보 1개를 "추천 시간"으로 표시하고, '
                '동점이면 빨래가 더 빨리 마르는 쪽을 우선합니다. '
                '강수가 추천 시점 직전·직후에 있거나 일몰까지 충분히 마르지 않으면 점수가 감점됩니다.',
          ),
          const _InfoCard(
            icon: Icons.checkroom,
            title: '빨래 종류',
            body: '얇음(LIGHT) < 보통(MEDIUM) < 두꺼움(HEAVY) 순으로 마르는 데 필요한 건조력이 다릅니다. '
                '같은 날씨라도 두꺼운 빨래는 점수가 더 낮게, 얇은 빨래는 점수가 더 높게 나옵니다. '
                '빨래 양은 일반 가정 기준(보통)으로 계산합니다.',
          ),

          const SizedBox(height: 16),
          const _InfoCard(
            icon: Icons.info_outline,
            title: '면책 안내',
            body: '점수와 추천 시간은 예보를 기반으로 한 추정치입니다. '
                '실제 날씨·환경에 따라 결과가 달라질 수 있으니 참고용으로 '
                '활용해주세요.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF3A7BD5),
          fontSize: 14,
        ),
      ),
    );
  }
}

class _GradeInfo {
  const _GradeInfo({
    required this.range,
    required this.label,
    required this.color,
    required this.icon,
    required this.desc,
  });
  final String range;
  final String label;
  final Color color;
  final String icon;
  final String desc;
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.info});
  final _GradeInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: info.color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(info.icon, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      info.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: info.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      info.range,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  info.desc,
                  style: const TextStyle(
                      fontSize: 12.5, color: Colors.black87, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactorInfo {
  const _FactorInfo({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

class _FactorCard extends StatelessWidget {
  const _FactorCard({required this.info});
  final _FactorInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3EAF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(info.icon, size: 22, color: const Color(0xFF3A7BD5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text(info.body,
                    style: const TextStyle(
                        fontSize: 12.5, color: Colors.black87, height: 1.4)),
              ],
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FA),
        borderRadius: BorderRadius.circular(14),
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
                        fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12.5, color: Colors.black87, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
