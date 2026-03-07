import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/features/auth/screens/welcome_screen.dart';
import 'package:flutter_project/features/home/data/pharmacy_repository.dart';
import 'package:flutter_project/features/home/models/pharmacy_vitamin.dart';
import 'package:flutter_project/home_screen.dart';

void main() {
  testWidgets('welcome screen fits on iPhone sized viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: WelcomeScreen(onNext: _noop)),
    );

    await tester.pumpAndSettle();

    expect(find.text('Далее'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows empty pharmacy state when there are no vitamins', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userId: 'user-1',
          userEmail: 'test@example.com',
          onSignOut: () async {},
          pharmacyRepository: _FakePharmacyRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Аптечка'), findsAtLeastNWidgets(1));
    expect(find.text('Добавить витамин'), findsOneWidget);
    expect(find.textContaining('Добавьте свои витамины'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}

class _FakePharmacyRepository implements PharmacyRepository {
  @override
  Future<List<PharmacyVitamin>> fetchVitamins() async => const [];
}
