import 'package:flutter_test/flutter_test.dart';
import 'package:neurolab/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const NeuroLabApp());

    // Verify loading screen appears initially
    expect(find.text('NeuroLab'), findsOneWidget);
  });
}
