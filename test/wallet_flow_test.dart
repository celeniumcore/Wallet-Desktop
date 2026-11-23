import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:celenium_wallet/main.dart';
import 'package:celenium_wallet/screens/login_screen.dart';
import 'package:celenium_wallet/screens/onboarding_screen.dart';
import 'package:celenium_wallet/screens/wallet_shell.dart';
import 'package:celenium_wallet/services/cen_wallet.dart';
import 'package:celenium_wallet/services/wallet_storage.dart';
import 'package:celenium_wallet/strings.dart';

/// BIP39 all-zero-entropy vector: valid checksum, fixed address.
const _phrase =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

Future<void> _seedSavedWallet() async {
  final wallet =
      CenWallet.fromMnemonic(Mnemonic.fromPhrase(_phrase), CenNetwork.mainnet);
  await WalletStorage.registerWallet(_phrase, address: wallet.address,
      label: 'Wallet 1');
  // Logged-out state: wallets stay, active pointer and legacy mirror go.
  await WalletStorage.forgetActiveWallet();
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int tries = 40,
}) async {
  for (var i = 0; i < tries; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .join(' | ');
  expect(finder, findsWidgets, reason: 'timed out waiting for $finder\nTexts: $texts');
}

Future<void> _bootToLogin(WidgetTester tester) async {
  await _seedSavedWallet();
  await tester.pumpWidget(const CenApp());
  await _settleReal(tester);
  await _pumpUntil(tester, find.text(S.buatWalletBaru));
  expect(find.byType(LoginScreen), findsOneWidget);
}

/// Lets real async work (asset loading, storage) finish inside a widget test;
/// `pump` alone only advances fake time.
Future<void> _settleReal(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 200),
      ));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Asset reads bind to the zone that starts them, so load the BIP39 list
  // once here; every widget then hits the process cache.
  setUpAll(() async {
    await bip39Wordlist();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    S.previewChosen(true);
  });

  testWidgets('creating a wallet from the picker lands on the dashboard',
      (tester) async {
    await _bootToLogin(tester);

    await tester.tap(find.text(S.buatWalletBaru));
    await tester.pump();
    await _pumpUntil(tester, find.text(S.imporFrasa));
    await _settleReal(tester);

    await tester.tap(find.widgetWithText(FilledButton, S.buatWalletBaru));
    await _pumpUntil(tester, find.byType(WalletShell));

    expect(find.byType(WalletShell), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('importing a recovery phrase from the picker opens the dashboard',
      (tester) async {
    await _bootToLogin(tester);

    await tester.tap(find.text(S.pulihkanWallet));
    await tester.pump();
    await _pumpUntil(tester, find.byType(TextField));
    await _settleReal(tester);

    await tester.enterText(find.byType(TextField), _phrase);
    await tester.pump();
    await tester.ensureVisible(find.text(S.masukDompet));
    await tester.pump();
    await tester.tap(find.text(S.masukDompet));
    await _pumpUntil(tester, find.byType(WalletShell));

    expect(find.byType(WalletShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('back button on the create flow returns to the picker',
      (tester) async {
    await _bootToLogin(tester);

    await tester.tap(find.text(S.buatWalletBaru));
    await tester.pump();
    await _pumpUntil(tester, find.text(S.imporFrasa));
    expect(find.text(S.kembali), findsOneWidget);

    await tester.tap(find.text(S.kembali));
    await _pumpUntil(tester, find.byType(LoginScreen));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mistyped phrase is rejected instead of opening an empty wallet',
      (tester) async {
    await _bootToLogin(tester);

    await tester.tap(find.text(S.pulihkanWallet));
    await tester.pump();
    await _pumpUntil(tester, find.byType(TextField));
    await _settleReal(tester);

    // One word swapped: length is still 12, checksum no longer matches.
    final bad = _phrase.replaceFirst('about', 'abandon');
    await tester.enterText(find.byType(TextField), bad);
    await tester.pump();
    await tester.ensureVisible(find.text(S.masukDompet));
    await tester.pump();
    await tester.tap(find.text(S.masukDompet));
    await _pumpUntil(tester, find.text(S.errFrasaChecksum));

    expect(find.text(S.errFrasaChecksum), findsOneWidget);
    expect(find.byType(WalletShell), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
