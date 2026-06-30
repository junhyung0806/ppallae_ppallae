import 'package:flutter_test/flutter_test.dart';
import 'package:ppallae_ppallae/api/ppallae_api_client.dart';
import 'package:ppallae_ppallae/features/laundry/grade_utils.dart';

void main() {
  group('gradeFromScore 경계값', () {
    test('각 등급 임계값에서 올바른 등급을 반환한다', () {
      expect(gradeFromScore(100), 'EXCELLENT');
      expect(gradeFromScore(85), 'EXCELLENT');
      expect(gradeFromScore(84), 'GOOD');
      expect(gradeFromScore(70), 'GOOD');
      expect(gradeFromScore(69), 'NORMAL');
      expect(gradeFromScore(50), 'NORMAL');
      expect(gradeFromScore(49), 'BAD');
      expect(gradeFromScore(30), 'BAD');
      expect(gradeFromScore(29), 'VERY_BAD');
      expect(gradeFromScore(0), 'VERY_BAD');
    });

    test('gradeLabel은 한글 라벨로 매핑된다', () {
      expect(gradeLabel('EXCELLENT'), '최고');
      expect(gradeLabel('GOOD'), '좋음');
      expect(gradeLabel('NORMAL'), '보통');
      expect(gradeLabel('BAD'), '나쁨');
      expect(gradeLabel('VERY_BAD'), '최악');
      expect(gradeLabel('UNKNOWN'), 'UNKNOWN'); // 알 수 없는 등급은 원문 유지
    });
  });

  group('PpallaeApiClient base URL', () {
    test('주입한 baseUrl을 그대로 사용한다', () {
      final client =
          PpallaeApiClient(baseUrl: 'https://api.example.com/api/v1');
      expect(client.baseUrl, 'https://api.example.com/api/v1');
    });

    test('기본 baseUrl은 /api/v1 로 끝난다 (운영 빌드 시 dart-define으로 교체)', () {
      // 운영 release 빌드는 --dart-define=PPALLAE_API_BASE_URL=https://... 로 주입한다.
      // 미주입 시 기본값은 로컬 개발용이며 반드시 /api/v1 접미사를 가진다.
      final client = PpallaeApiClient();
      expect(client.baseUrl, endsWith('/api/v1'));
    });
  });
}
