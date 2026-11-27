import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import '../strings.dart';
import '../services/cen_wallet.dart';

/// Receive page: QR on the left, address and network details on the right.
/// Heading padding and type scale match the wallet page so both titles sit on
/// the same line when switching tabs.
class TerimaScreen extends StatelessWidget {
  const TerimaScreen({super.key, required this.wallet});
  final CenWallet wallet;

  @override
  Widget build(BuildContext context) {
    final address = wallet.address;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final pad = wide ? 34.0 : 16.0;
        // Below this width the QR and the address can no longer share a row
        // without squeezing the code, so they stack.
        final stacked = constraints.maxWidth < 760;

        // Named so the details column can end on the QR artwork's edge instead
        // of guessing where the code stops.
        const double qrArt = 200;
        const double qrFrame = 16;
        const double blockPad = 24;

        final qrBlock = Container(
          padding: const EdgeInsets.all(blockPad),
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            color: CenTheme.elevated,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(qrFrame),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: address,
              version: QrVersions.auto,
              size: qrArt,
              gapless: false,
            ),
          ),
        );

        Widget detailsBlock({required bool alignToQrBottom}) {
          final copyButton = SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: CenTheme.primaryBtn,
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
              child: Text(S.salinAlamat),
            ),
          );

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.alamatWallet,
                style: CenTheme.body(12, color: CenTheme.muted),
              ),
              const SizedBox(height: 10),
              SelectableText(
                address,
                // Two lines keeps the column inside the QR block's height, so
                // the copy button can end level with the QR's lower edge. The
                // full string is still selectable and copied by the button.
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 13,
                  color: CenTheme.txt,
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
              ),
              // 20 (not 28) keeps the whole column inside the QR block height.
              const SizedBox(height: 20),
              _row(S.jaringan, 'CEN · Mainnet'),
              const SizedBox(height: 8),
              _row(S.tipe, 'PubKeyHash'),
            ],
          );

          if (alignToQrBottom) {
            // Top padding matches the QR white-frame top; bottom padding matches
            // the QR white-frame bottom so the copy button sits level with the
            // QR code's lower edge. Spacing only — card size unchanged.
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, blockPad, 0, blockPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  info,
                  const Spacer(),
                  const SizedBox(height: 16),
                  copyButton,
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: blockPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                info,
                const SizedBox(height: 24),
                copyButton,
              ],
            ),
          );
        }

        // The page has to fill the pane. A bare scroll view shrink-wraps to
        // its content, and the shell's row then centres that short box —
        // which is what pushed the heading far below the sidebar brand.
        return SizedBox.expand(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, wide ? 26 : 18, pad, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        S.terimaCEN,
                        style: CenTheme.display(24,
                            letterSpacing: -0.2, height: 1.15),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        S.mainnetAlamatAktif,
                        style: CenTheme.body(12, color: CenTheme.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 640),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: CenTheme.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: CenTheme.line),
                    ),
                    child: stacked
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              qrBlock,
                              const SizedBox(height: 24),
                              detailsBlock(alignToQrBottom: false),
                            ],
                          )
                        // Fixed height instead of IntrinsicHeight: the QR widget
                        // is a LayoutBuilder, and its intrinsics are unreliable
                        // in release, so the row must be sized arithmetically.
                        : SizedBox(
                            height: qrArt + 2 * qrFrame + 2 * blockPad,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: qrBlock),
                                const SizedBox(width: 28),
                                Expanded(
                                    child: detailsBlock(alignToQrBottom: true)),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    S.terimaNote,
                    textAlign: TextAlign.center,
                    style: CenTheme.body(11, color: CenTheme.muted),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CenTheme.body(13, color: CenTheme.muted)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: CenTheme.txt,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
