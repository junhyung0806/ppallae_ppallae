import '../../features/recommendation/models/recommendation_status.dart';
import 'laundry_status.dart';

extension RecommendationStatusToLaundryStatus on RecommendationStatus {
  LaundryStatus get asLaundryStatus {
    switch (this) {
      case RecommendationStatus.good:
        return LaundryStatus.good;
      case RecommendationStatus.normal:
        return LaundryStatus.normal;
      case RecommendationStatus.bad:
        return LaundryStatus.bad;
    }
  }
}
