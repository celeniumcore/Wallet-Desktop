import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:celenium_wallet/screens/dompet_screen.dart';
import 'package:celenium_wallet/screens/kirim_screen.dart';
import 'package:celenium_wallet/screens/wallet_shell.dart';
import 'package:celenium_wallet/services/bridge_api_simple.dart';
import 'package:celenium_wallet/services/cen_wallet.dart';
import 'package:celenium_wallet/services/wallet_data.dart';
import 'package:celenium_wallet/strings.dart';

const _phrase =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

class _OnlineApi extends BridgeApi {
  _OnlineApi() : super(baseUrl: 'http://127.0.0.1:1');

  @override
  Future<int> fetchBalance(String address) async => 250000000;

  @override
  Future<int> fetchFee() async => 100000;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    S.previewChosen(true);
    S.setLocale('id');
  });

  testWidgets('wallet send action switches to the single send tab',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final wallet = CenWallet.fromMnemonic(
      Mnemonic.fromPhrase(_phrase),
      CenNetwork.mainnet,
    );
    final api = _OnlineApi();
    await tester.pumpWidget(MaterialApp(
      home: WalletShell(
        wallet: wallet,
        api: api,
        previewData: WalletData(),
        onLogout: () async {},
      ),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(DompetScreen), findsOneWidget);
    expect(find.byType(KirimScreen), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, S.kirim));
    await tester.pump();

    expect(find.byType(KirimScreen), findsOneWidget);
    expect(find.byType(DompetScreen), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
