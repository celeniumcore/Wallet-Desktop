import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import '../strings.dart';
import '../services/cen_wallet.dart';

class TerimaScreen extends StatelessWidget {
  const TerimaScreen({super.key, required this.wallet});
  final CenWallet wallet;

  @override
  Widget build(BuildContext context) {
    final address = wallet.address;

    return Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(S.terimaCEN, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CenTheme.txt)),
              Text(S.mainnetAlamatAktif, style: TextStyle(fontSize: 12, color: CenTheme.sub)),
            ],
          ),
          SizedBox(height: 40),
          Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 640),
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: CenTheme.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: CenTheme.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: CenTheme.elevated,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data: address,
                            version: QrVersions.auto,
                            size: 200,
                            gapless: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(S.alamatWallet, style: TextStyle(fontSize: 12, color: CenTheme.sub)),
                        SizedBox(height: 12),
                        SelectableText(
                          address,
                          style: TextStyle(fontSize: 13, color: CenTheme.txt, fontFamily: 'monospace', height: 1.7),
                        ),
                        SizedBox(height: 20),
                        _row(S.jaringan, 'CEN · Mainnet'),
                        _row(S.tipe, 'PubKeyHash'),
                        SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: CenTheme.primaryBtn,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: address));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(S.alamatDisalin), backgroundColor: CenTheme.card,
                                      duration: Duration(seconds: 1)),
                                  );
                                },
                                child: Text(S.salinAlamat),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            S.terimaNote,
            style: TextStyle(fontSize: 11, color: CenTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: CenTheme.sub)),
          Text(value, style: TextStyle(fontSize: 12.5, color: CenTheme.txt, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
