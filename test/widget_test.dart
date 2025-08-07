import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_iptv/main.dart';
import 'package:shoof_iptv/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('Shoof IPTV loads SplashScreen initially', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ShoofIPTVApp()));

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
