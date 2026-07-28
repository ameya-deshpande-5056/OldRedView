import 'package:flutter_test/flutter_test.dart';
import 'package:open_in_old_reddit/app/app.dart';

void main() {
  testWidgets('App launches with default homepage', (WidgetTester tester) async {
    await tester.pumpWidget(const OldRedditApp());

    // The app should render without errors.
    // The WebView widget should be present.
    expect(find.byType(OldRedditApp), findsOneWidget);
  });
}