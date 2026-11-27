import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:celenium_wallet/screens/terima_screen.dart';
import 'package:celenium_wallet/services/cen_wallet.dart';
import 'package:celenium_wallet/strings.dart';

const _phrase =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() {
  final wallet = CenWallet.fromMnemonic(
    Mnemonic.fromPhrase(_phrase),
    CenNetwork.mainnet,
  );

  testWidgets('receive page keeps QR beside the address, stacks when narrow',
      (tester) async {
    for (final size in const [
      Size(1280, 820),
      Size(1024, 720),
      Size(760, 700),
      Size(600, 700),
      Size(390, 720),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TerimaScreen(wallet: wallet)),
      ));
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull, reason: 'overflow at $size');
      expect(find.text(S.terimaCEN), findsOneWidget);
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        wallet.address,
      );

      final qr = tester.getRect(find.byType(QrImageView));
      final address = tester.getRect(find.byType(SelectableText));
      if (size.width >= 760) {
        expect(address.left, greaterThan(qr.right),
            reason: 'address sits right of the QR at $size');
      } else {
        expect(address.top, greaterThan(qr.bottom),
            reason: 'address stacks under the QR at $size');
      }
    }
  });

  testWidgets('heading shares the page padding used by the other tabs',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 820);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TerimaScreen(wallet: wallet)),
    ));
    await tester.pump(const Duration(milliseconds: 50));

    final title = tester.getRect(find.text(S.terimaCEN));
    expect(title.top, closeTo(26, 1));
    expect(title.left, closeTo(34, 1));
  });
}
