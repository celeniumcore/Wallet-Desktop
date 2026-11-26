import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:celenium_wallet/screens/kirim_screen.dart';
import 'package:celenium_wallet/services/bridge_api_simple.dart';
import 'package:celenium_wallet/services/cen_wallet.dart';
import 'package:celenium_wallet/strings.dart';

const _phrase =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

class _OfflineApi extends BridgeApi {
  _OfflineApi() : super(baseUrl: 'http://127.0.0.1:1');
}

class _FeeApi extends BridgeApi {
  _FeeApi() : super(baseUrl: 'http://127.0.0.1:1');

  @override
  Future<int> fetchFee() async => 1000000;
}

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size, {BridgeApi? api}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    final wallet = CenWallet.fromMnemonic(
      Mnemonic.fromPhrase(_phrase),
      CenNetwork.mainnet,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KirimScreen(wallet: wallet, api: api ?? _OfflineApi()),
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

  testWidgets('form card ends just below the send button', (tester) async {
    await pumpAt(tester, const Size(1280, 720), api: _FeeApi());
    final card = tester.getRect(find.byKey(const ValueKey('kirim-form-card')));
    final button = tester.getRect(find.byType(FilledButton).last);
    expect(card.bottom - button.bottom, lessThan(40));
    expect(card.bottom, lessThan(620),
        reason: 'card must not stretch down the empty viewport');
  });

  testWidgets('fee and total follow the entered amount', (tester) async {
    await pumpAt(tester, const Size(1280, 720), api: _FeeApi());
    await tester.pump();
    expect(find.text('0,0100 CEN'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '2');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text(S.totalDipotong), findsOneWidget);
    expect(find.text('2,0100 CEN'), findsOneWidget,
        reason: 'total must be amount + network fee');
    expect(tester.takeException(), isNull);
  });
}
