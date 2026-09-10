import 'package:flutter_test/flutter_test.dart';
import 'package:manuel_mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app routes unauthenticated users to sign in', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ManuelAdvMobProg());
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
