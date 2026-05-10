import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_city/app/app.dart';

void main() {
  testWidgets('app boots into Taskoria splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ProductivityCityApp()));
    await tester.pump();

    expect(find.text('Taskoria'), findsOneWidget);
  });
}
