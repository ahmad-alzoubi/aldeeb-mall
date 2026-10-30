import 'package:flutter_test/flutter_test.dart';
import 'package:aldeeb_mall_app/main.dart';

void main() {
  testWidgets('Aldeeb Mall app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AldeebMallApp());
    expect(find.byType(AldeebMallApp), findsOneWidget);
  });
}
