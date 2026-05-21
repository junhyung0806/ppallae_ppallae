import 'package:flutter/material.dart';

enum LaundryStatus { good, normal, bad }

extension LaundryStatusX on LaundryStatus {
  String get label {
    switch (this) {
      case LaundryStatus.good:
        return '좋음';
      case LaundryStatus.normal:
        return '보통';
      case LaundryStatus.bad:
        return '나쁨';
    }
  }

  String get shortDescription {
    switch (this) {
      case LaundryStatus.good:
        return '바짝 잘 마를 날씨';
      case LaundryStatus.normal:
        return '실내 건조 보조가 필요해요';
      case LaundryStatus.bad:
        return '급한 빨래만 추천해요';
    }
  }

  IconData get icon {
    switch (this) {
      case LaundryStatus.good:
        return Icons.wb_sunny_rounded;
      case LaundryStatus.normal:
        return Icons.cloud_queue_rounded;
      case LaundryStatus.bad:
        return Icons.umbrella_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LaundryStatus.good:
        return const Color(0xFF2EAD6F);
      case LaundryStatus.normal:
        return const Color(0xFFF5A623);
      case LaundryStatus.bad:
        return const Color(0xFFE0565B);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case LaundryStatus.good:
        return const Color(0xFFE5F7EE);
      case LaundryStatus.normal:
        return const Color(0xFFFFF3DF);
      case LaundryStatus.bad:
        return const Color(0xFFFFE7E8);
    }
  }
}
