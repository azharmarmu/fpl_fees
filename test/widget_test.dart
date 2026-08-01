import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fpl_fees/main.dart';
import 'package:fpl_fees/services/fpl_store.dart';
import 'package:fpl_fees/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login screen shows FPL branding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = FplStore();
    final session = SessionService();
    await store.init();
    await session.load();

    await tester.pumpWidget(
      FplFeesApp(store: store, session: session),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('FPL'), findsWidgets);
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text('Player'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}
