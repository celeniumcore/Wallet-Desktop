import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:celenium_wallet/screens/onboarding_screen.dart';
import 'package:celenium_wallet/strings.dart';
import 'package:celenium_wallet/theme.dart';

Widget _wrap(Widget child) => MaterialApp(theme: CenTheme.dark, home: child);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.physicalSizeTestValue = const Size(1200, 900);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  tearDown(() {
    S.setLocale('id');
    S.previewChosen(true);
  });

  test('string table switches locale', () {
    S.previewChosen(true);
    S.setLocale('id');
    expect(S.pilihBahasa, 'Pilih bahasa');
    expect(S.kirim, 'Kirim');

    S.setLocale('en');
    expect(S.pilihBahasa, 'Choose your language');
    expect(S.kirim, 'Send');
    expect(S.saldoTersedia, 'Available balance');
  });

  testWidgets('language step comes before wallet creation', (tester) async {
    S.previewChosen(false);
    S.setLocale('id');

    await tester.pumpWidget(_wrap(OnboardingScreen(onDone: (_, __) {})));
    await tester.pumpAndSettle();

    expect(find.text('Pilih bahasa'), findsOneWidget);
    expect(find.text('Buat wallet baru'), findsNothing);
    expect(find.text('Bahasa Indonesia'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('tapping English selects the English locale', (tester) async {
    S.previewChosen(false);
    S.setLocale('id');

    await tester.pumpWidget(_wrap(OnboardingScreen(onDone: (_, __) {})));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(S.locale, 'en');
  });

  testWidgets('English locale renders English onboarding copy', (tester) async {
    S.previewChosen(false);
    S.setLocale('en');

    await tester.pumpWidget(_wrap(OnboardingScreen(onDone: (_, __) {})));
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('Buat wallet baru'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Create new wallet'), findsOneWidget);
  });

  testWidgets('returning users go straight to the wallet step', (tester) async {
    S.previewChosen(true);
    S.setLocale('id');

    await tester.pumpWidget(_wrap(OnboardingScreen(onDone: (_, __) {})));
    await tester.pumpAndSettle();

    expect(find.text('Buat wallet baru'), findsOneWidget);
    expect(find.text('Pilih bahasa'), findsNothing);
  });
}
