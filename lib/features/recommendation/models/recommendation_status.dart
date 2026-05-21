enum RecommendationStatus { good, normal, bad }

extension RecommendationStatusX on RecommendationStatus {
  String get label {
    switch (this) {
      case RecommendationStatus.good:
        return '좋음';
      case RecommendationStatus.normal:
        return '보통';
      case RecommendationStatus.bad:
        return '나쁨';
    }
  }
}
