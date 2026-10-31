import 'package:flutter_test/flutter_test.dart';
import 'package:aynox_library/main.dart';

void main() {
  testWidgets('AYNOX Library smoke test and widget tree build', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AynoxLibraryApp());
    await tester.pump();
    expect(find.byType(AynoxLibraryApp), findsOneWidget);
  });
}
