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
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final pad = wide ? 28.0 : 20.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, wide ? 26 : 18, pad, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.terimaCEN,
                style: CenTheme.display(24, letterSpacing: -0.2, height: 1.15),
              ),
              const SizedBox(height: 4),
              Text(
                S.terimaDesc,
                style: CenTheme.body(
                  13,
                  color: CenTheme.sub,
                  weight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              SizedBox(height: wide ? 20 : 16),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: CenTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: CenTheme.line),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
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
                            const SizedBox(height: 20),
                            Text(
                              S.alamatDompetAnda,
                              style: CenTheme.body(12, color: CenTheme.muted),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              address,
                              textAlign: TextAlign.center,
                              style: CenTheme.mono(12.5,
                                  color: CenTheme.txt, height: 1.5),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: CenTheme.sub,
                                  side: const BorderSide(color: CenTheme.line),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: Text(S.salinAlamat),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: address));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(S.alamatDisalin),
                                      backgroundColor: CenTheme.card,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: CenTheme.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CenTheme.line),
                        ),
                        child: Column(
                          children: [
                            _row(S.jaringan, 'CEN · Mainnet'),
                            Divider(height: 18, color: CenTheme.line),
                            _row(S.tipe, 'PubKeyHash'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: CenTheme.body(13, color: CenTheme.sub)),
        Text(value, style: CenTheme.mono(12.5, color: CenTheme.txt)),
      ],
    );
  }
}
