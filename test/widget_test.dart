import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_project/features/auth/screens/welcome_screen.dart';
import 'package:flutter_project/features/home/data/pharmacy_repository.dart';
import 'package:flutter_project/features/home/models/home_tab.dart';
import 'package:flutter_project/features/home/models/pharmacy_reminder.dart';
import 'package:flutter_project/features/home/models/pharmacy_reminder_input.dart';
import 'package:flutter_project/features/home/models/pharmacy_vitamin.dart';
import 'package:flutter_project/features/home/models/vitamin_draft.dart';
import 'package:flutter_project/features/home/models/vitamin_catalog_item.dart';
import 'package:flutter_project/features/home/models/weekday.dart';
import 'package:flutter_project/features/home/screens/pharmacy_flow_screens.dart';
import 'package:flutter_project/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const <String, Object>{});

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

  testWidgets('renders add vitamin screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddVitaminScreen(
          repository: _FakePharmacyRepository(),
          onFlowCompleted: _noop,
          onTabRequested: _noopTab,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Название'), findsOneWidget);
    expect(find.text('Вид витамина'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows mapped dose unit inside the dose field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddVitaminScreen(
          repository: _FakePharmacyRepository(),
          onFlowCompleted: _noop,
          onTabRequested: _noopTab,
          initialDraft: VitaminDraft.empty().copyWith(type: 'Спрей'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Введите количество'), findsOneWidget);
    expect(find.text('нажатия'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adds unit after vitamin type is selected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddVitaminScreen(
          repository: _FakePharmacyRepository(),
          onFlowCompleted: _noop,
          onTabRequested: _noopTab,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '5');
    await tester.pump();

    expect(find.text('5'), findsOneWidget);
    expect(find.text('нажатий'), findsNothing);

    await tester.tap(find.text('Вид витамина'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Спрей'));
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
    expect(find.text('нажатий'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders vitamin details screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VitaminDetailsScreen(
          repository: _FakePharmacyRepository(),
          reminderId: 'vit-d',
          onFlowCompleted: _noop,
          onTabRequested: _noopTab,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Витамин D'), findsOneWidget);
    expect(find.text('Настроить'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('maps dose units by vitamin type', () {
    expect(
      PharmacyFlowLogic.doseUnitFor(type: 'Таблетки', amountText: '2'),
      'шт',
    );
    expect(
      PharmacyFlowLogic.doseUnitFor(type: 'Капсулы', amountText: '1'),
      'шт',
    );
    expect(
      PharmacyFlowLogic.doseUnitFor(type: 'Порошок', amountText: '5'),
      'г',
    );
    expect(
      PharmacyFlowLogic.doseUnitFor(type: 'Жидкость', amountText: '10'),
      'мл',
    );
  });

  test('pluralizes drops and sprays correctly', () {
    expect(
      PharmacyFlowLogic.doseUnitFor(type: 'Капли', amountText: '1'),
      'капля',
    );
    expect(
      PharmacyFlowLogic.doseUnitFor(type: 'Капли', amountText: '2'),
      'капли',
    );
    expect(
      PharmacyFlowLogic.doseUnitFor(type: 'Капли', amountText: '5'),
      'капель',
    );
    expect(
      PharmacyFlowLogic.doseUnitFor(type: 'Спрей', amountText: '1'),
      'нажатие',
    );
    expect(
      PharmacyFlowLogic.doseUnitFor(type: 'Спрей', amountText: '2'),
      'нажатия',
    );
    expect(
      PharmacyFlowLogic.doseUnitFor(type: 'Спрей', amountText: '5'),
      'нажатий',
    );
    expect(
      PharmacyFlowLogic.composeDose(type: 'Спрей', amountText: '5'),
      '5 нажатий',
    );
  });
}

void _noop() {}
void _noopTab(HomeTab _) {}

class _FakePharmacyRepository implements PharmacyRepository {
  @override
  Future<List<PharmacyVitamin>> fetchVitamins() async => const [];

  @override
  Future<List<PharmacyReminder>> fetchReminders() async {
    final reminder = await fetchReminder('vit-d');
    return reminder == null ? const <PharmacyReminder>[] : <PharmacyReminder>[reminder];
  }

  @override
  Future<String> createReminder(PharmacyReminderInput input) async => 'id';

  @override
  Future<void> deleteReminder(String reminderId) async {}

  @override
  Future<List<VitaminCatalogItem>> fetchCatalog([String query = '']) async => [
        const VitaminCatalogItem(
          id: 'vit-d',
          displayName: 'Витамин D',
          defaultUnit: 'капсула',
          interactionText: 'Следите за регулярностью приёма.',
          compatibilityText: 'Подходит для длительного курса.',
          contraindicationsText: 'Учитывайте индивидуальные ограничения.',
          defaultCondition: 'after_meal',
        ),
      ];

  @override
  Future<PharmacyReminder?> fetchReminder(String reminderId) async {
    if (reminderId != 'vit-d') {
      return null;
    }

    return PharmacyReminder(
      id: 'vit-d',
      title: 'Витамин D',
      isActive: true,
      form: 'capsule',
      dose: '1 капсула',
      condition: 'after_meal',
      note: 'После завтрака',
      catalogId: 'vit-d',
      catalog: const VitaminCatalogItem(
        id: 'vit-d',
        displayName: 'Витамин D',
        defaultUnit: 'капсула',
        interactionText: 'Следите за регулярностью приёма.',
        compatibilityText: 'Подходит для длительного курса.',
        contraindicationsText: 'Учитывайте индивидуальные ограничения.',
        defaultCondition: 'after_meal',
      ),
      course: ReminderCourse(
        startDate: DateTime(2026, 3, 6),
        endDate: DateTime(2026, 3, 20),
        timezone: 'Europe/Moscow',
      ),
      schedule: const ReminderSchedule(
        days: [Weekday.mon, Weekday.wed, Weekday.fri],
        times: ['09:00'],
      ),
      notificationPreferences: const ReminderNotificationPreferences(),
      contentOverrides: const ReminderContentOverrides(),
    );
  }

  @override
  Future<void> updateReminder(
    String reminderId,
    PharmacyReminderInput input,
  ) async {}
}
