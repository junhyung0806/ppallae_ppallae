import 'package:flutter_test/flutter_test.dart';
import 'package:ppallae_ppallae/app.dart';

void main() {
  testWidgets('bottom navigation tabs render', (tester) async {
    await tester.pumpWidget(const PpallaeApp());

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('주간'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('빨래하기 좋은 타이밍'), findsOneWidget);
  });
}
