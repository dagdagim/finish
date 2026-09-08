import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('FinishApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FinishApp());
    expect(find.text('FINISH'), findsOneWidget);

    // Pump and settle to let splash screen timer finish
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Need something\ndone?'), findsOneWidget);
  });
}
