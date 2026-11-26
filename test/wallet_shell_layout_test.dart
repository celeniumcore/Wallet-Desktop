import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  testWidgets('wallet shell lays out without overflow', (tester) async {
    final wallet = CenWallet.fromMnemonic(
      Mnemonic.fromPhrase(_phrase),
      CenNetwork.mainnet,
    );
    for (final size in const [
      Size(1280, 720),
      Size(1024, 700),
      Size(900, 640),
      Size(800, 600),
      Size(700, 560),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: WalletShell(
          wallet: wallet,
          api: _OnlineApi(),
          previewData: WalletData(),
          onLogout: () async {},
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: 'wallet overflow at $size');

      final send = find.widgetWithText(FilledButton, S.kirim).first;
      await tester.ensureVisible(send);
      await tester.pump();
      await tester.tap(send);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(KirimScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'send overflow at $size');
    }
  });
}