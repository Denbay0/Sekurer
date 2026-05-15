import 'package:flutter_test/flutter_test.dart';
import 'package:sekurer_mobile/main.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const SekurerApp());
    expect(find.text('Sekurer'), findsOneWidget);
  });
}
