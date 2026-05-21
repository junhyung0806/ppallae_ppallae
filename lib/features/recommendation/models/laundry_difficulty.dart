enum LaundryDifficulty {
  light(
    label: '가벼움',
    examples: ['티셔츠', '속옷', '얇은 운동복'],
    chipExamples: ['티셔츠', '속옷'],
    baseDryingMinutes: 120,
    description: '빠르게 마르는 빨래예요.',
  ),
  normal(
    label: '보통',
    examples: ['셔츠', '얇은 바지', '일반 상의'],
    chipExamples: ['셔츠', '얇은 니트'],
    baseDryingMinutes: 180,
    description: '일반적인 낮 시간 건조에 무리가 없어요.',
  ),
  heavy(
    label: '두꺼움',
    examples: ['청바지', '후드', '수건'],
    chipExamples: ['청바지', '후드'],
    baseDryingMinutes: 330,
    description: '가능하지만 건조 시간이 길어질 수 있어요.',
  ),
  extraHeavy(
    label: '초두꺼움',
    examples: ['이불', '담요', '패드류'],
    chipExamples: ['이불', '패딩'],
    baseDryingMinutes: 480,
    description: '날씨가 좋아도 오래 걸려 신중한 판단이 필요해요.',
  );

  const LaundryDifficulty({
    required this.label,
    required this.examples,
    required this.chipExamples,
    required this.baseDryingMinutes,
    required this.description,
  });

  final String label;
  final List<String> examples;
  final List<String> chipExamples;
  final int baseDryingMinutes;
  final String description;

  String get exampleSummary => examples.join(', ');
  String get chipLabel => '$label (${chipExamples.join(', ')})';

  String buildUserHint({
    required bool recommended,
    required bool exceedsEightHours,
  }) {
    if (this == LaundryDifficulty.extraHeavy) {
      return recommended && !exceedsEightHours
          ? '이불류는 가능하지만 건조 시간을 넉넉히 잡아주세요.'
          : '이불류는 오늘 건조 시간이 너무 길어 비추천이에요.';
    }

    if (this == LaundryDifficulty.heavy) {
      return recommended
          ? '청바지나 후드류는 가능하지만 오래 걸릴 수 있어요.'
          : '두꺼운 빨래는 건조가 늦어져 오늘은 비추천이에요.';
    }

    return recommended
        ? '$label 빨래는 오늘 무난하게 말릴 수 있어요.'
        : '$label 빨래는 오늘 실내 건조 보조가 필요해 보여요.';
  }
}
