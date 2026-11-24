import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:celenium_wallet/screens/kirim_screen.dart';
import 'package:celenium_wallet/services/bridge_api_simple.dart';
import 'package:celenium_wallet/services/cen_wallet.dart';

const _phrase =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

class _OfflineApi extends BridgeApi {
  _OfflineApi() : super(baseUrl: 'http://127.0.0.1:1');
}

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    final wallet = CenWallet.fromMnemonic(
      Mnemonic.fromPhrase(_phrase),
      CenNetwork.mainnet,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KirimScreen(wallet: wallet, api: _OfflineApi()),
      ),
    ));
    await tester.pump();
  }

  testWidgets('send form lays out at desktop sizes', (tester) async {
    for (final size in const [
      Size(1280, 720),
      Size(1024, 700),
      Size(800, 600),
      Size(640, 560),
      Size(480, 560),
    ]) {
      await pumpAt(tester, size);
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
    }
  });
}
