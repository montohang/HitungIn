import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/app.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('aplikasi bisa dijalankan dan membuka onboarding', (tester) async {
    final env = TestEnv();
    await tester.pumpWidget(ProviderScope(overrides: env.overrides, child: const HitungInApp()));
    await tester.pumpAndSettle();
    expect(find.text('Data keuanganmu tetap di HP-mu'), findsOneWidget);
    await env.db.close();
  });
}
