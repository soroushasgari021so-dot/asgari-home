import 'package:flutter_test/flutter_test.dart';
import 'package:asgari_home/main.dart';

void main() {
  testWidgets('shows setup notice when backend configuration is missing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AsgariApp(configured: false));

    expect(find.textContaining('تنظیمات اتصال به پایگاه داده'), findsOneWidget);
  });
}
