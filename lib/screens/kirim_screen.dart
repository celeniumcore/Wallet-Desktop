import 'dart:async';

import 'package:flutter/material.dart';
import '../format.dart';
import '../theme.dart';
import '../strings.dart';
import '../services/cen_wallet.dart';
import '../services/bridge_api_simple.dart';
import '../services/wallet_storage.dart';
import '../services/wallet_data.dart';
import '../services/biometric_service.dart';
import 'pin_screen.dart';
import 'scan_qr_screen.dart';

class KirimScreen extends StatefulWidget {
  const KirimScreen({
    super.key,
    required this.wallet,
    required this.api,
    this.initialRecipient,
  });
  final CenWallet wallet;
  final BridgeApi api;

  /// Prefilled recipient, used when sending from a saved address row.
  final String? initialRecipient;

  @override
  State<KirimScreen> createState() => _KirimScreenState();
}

class _KirimScreenState extends State<KirimScreen> {
  final _addrCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _sending = false;
  String? _status;
  bool _success = false;

  /// Mirrors the bridge's anti-dust floor; the server rejects lower amounts.
  static const int _minTransferPradha = 1000;

  int? _feePradha;
  bool _feeLoading = true;
  bool _feeFailed = false;
  Timer? _feeDebounce;

  @override
  void initState() {
    super.initState();
    final preset = widget.initialRecipient;
    if (preset != null && preset.isNotEmpty) _addrCtrl.text = preset;
    _amountCtrl.addListener(_onAmountChanged);
    _loadFee();
  }

  @override
  void dispose() {
    _feeDebounce?.cancel();
    _addrCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
    _feeDebounce?.cancel();
    _feeDebounce = Timer(const Duration(milliseconds: 400), _loadFee);
  }

  Future<void> _loadFee() async {
    if (!mounted) return;
    setState(() => _feeLoading = true);
    try {
      final fee = await widget.api.fetchFee();
      if (!mounted) return;
      setState(() {
        _feePradha = fee;
        _feeLoading = false;
        _feeFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _feeLoading = false;
        _feeFailed = true;
      });
    }
  }

  int get _amountPradha {
    final amount =
        double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) return 0;
    return (amount * pradhaPerCen).round();
  }

  Future<bool> _authorize() async {
    final biometricEnabled = await WalletStorage.loadBiometric();
    if (biometricEnabled) {
      final available = await BiometricService.instance.isAvailable();
      if (available) {
        final ok = await BiometricService.instance.authenticate(
          reason: S.biometrikKirim,
        );
        if (ok) return true;
        // If biometric fails/cancelled, fall through to PIN if set
      }
    }
    final hasPin = await WalletStorage.hasPin();
    if (!hasPin) return true; // no protection configured

    if (!mounted) return false;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PinScreen(
          onVerified: () => Navigator.of(context).pop(true),
          allowBiometric: false,
          title: S.konfirmasiPengiriman,
          subtitle: S.konfirmasiSub,
        ),
        fullscreenDialog: true,
      ),
    );
    return ok == true;
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanQrScreen()),
    );
    if (!mounted) return;
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _addrCtrl.text = result.trim();
      });
    }
  }

  Future<void> _send() async {
    final addr = _addrCtrl.text.trim();
    final amountStr = _amountCtrl.text.trim().replaceAll(',', '.');
    if (addr.isEmpty) {
      setState(() {
        _status = S.alamatWajib;
        _success = false;
      });
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      setState(() {
        _status = S.jumlahTidakValid;
        _success = false;
      });
      return;
    }
    final pradha = (amount * pradhaPerCen).round();
    if (pradha < _minTransferPradha) {
      setState(() {
        _status = S.minimalKirim;
        _success = false;
      });
      return;
    }

    final authorized = await _authorize();
    if (!authorized) {
      if (!mounted) return;
      setState(() {
        _status = S.verifikasiGagal;
        _success = false;
      });
      return;
    }

    setState(() {
      _sending = true;
      _status = null;
    });
    try {
      final result = await widget.api.sendCoins(
        from: widget.wallet.address,
        to: addr,
        amountPradha: pradha,
        privateKeyHex: widget.wallet.privateKeyHex,
      );
      try {
        final data = await WalletDataStore.load(widget.wallet.address);
        final changed = data.recordSend(
          to: addr,
          amountPradha: pradha,
          feePradha: result.feePradha,
          txid: result.txid,
          now: DateTime.now(),
        );
        if (changed) await WalletDataStore.save(widget.wallet.address, data);
      } catch (_) {
        // The coins already left. A failed history write must not be shown as
        // a failed send, or the user retries and pays twice.
      }
      if (!mounted) return;
      setState(() {
        _sending = false;
        _success = true;
        _status = S.terkirimTxid(result.txid, result.feePradha);
        _amountCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _success = false;
        _status = S.gagal(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final horizontalPad = wide ? 34.0 : 20.0;
        final topPad = wide ? 26.0 : 18.0;
        const bottomPad = 26.0;

        final formCard = Container(
          key: const ValueKey('kirim-form-card'),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: CenTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CenTheme.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.alamatTujuan,
                  style: const TextStyle(fontSize: 13, color: CenTheme.sub)),
              const SizedBox(height: 8),
              TextField(
                controller: _addrCtrl,
                style: const TextStyle(
                    fontSize: 14, color: CenTheme.txt, fontFamily: 'monospace'),
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'cen69:...',
                  hintStyle: const TextStyle(color: CenTheme.muted),
                  filled: true,
                  fillColor: CenTheme.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CenTheme.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CenTheme.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CenTheme.acid),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _sending ? null : _scanQr,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CenTheme.txt,
                      side: const BorderSide(color: CenTheme.line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded,
                        size: 18, color: CenTheme.acid),
                    label: Text(S.pindaiQR,
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.scanAlamatSub,
                      style:
                          const TextStyle(fontSize: 12, color: CenTheme.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(S.jumlahCEN,
                  style: const TextStyle(fontSize: 13, color: CenTheme.sub)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    fontSize: 18,
                    color: CenTheme.txt,
                    fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: const TextStyle(color: CenTheme.muted),
                  filled: true,
                  fillColor: CenTheme.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CenTheme.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CenTheme.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CenTheme.acid),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  suffixText: 'CEN',
                  suffixStyle: const TextStyle(
                      color: CenTheme.sub, fontWeight: FontWeight.w600),
                ),
              ),
              if (_amountPradha > 0 && _amountPradha < _minTransferPradha) ...[
                const SizedBox(height: 8),
                Text(
                  S.minimalKirim,
                  style: const TextStyle(fontSize: 12, color: CenTheme.red),
                ),
              ],
              const SizedBox(height: 18),
              _FeeSummary(
                feePradha: _feePradha,
                amountPradha: _amountPradha,
                loading: _feeLoading,
                failed: _feeFailed,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  style: CenTheme.primaryBtn,
                  onPressed: (_sending ||
                          (_amountPradha > 0 &&
                              _amountPradha < _minTransferPradha))
                      ? null
                      : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: CenTheme.bg),
                        )
                      : const Icon(Icons.north_east_rounded),
                  label: Text(_sending ? S.mengirim : S.kirim),
                ),
              ),
              if (_status != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_success ? CenTheme.green : CenTheme.red)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (_success ? CenTheme.green : CenTheme.red)
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _status!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _success ? CenTheme.green : CenTheme.red,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

        final noticeCard = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CenTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CenTheme.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: CenTheme.sub, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  S.konfirmasiKirimDesc,
                  style: const TextStyle(
                      fontSize: 12.5, color: CenTheme.sub, height: 1.5),
                ),
              ),
            ],
          ),
        );

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPad, topPad, horizontalPad, bottomPad),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: wide ? 0 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.kirimCEN,
                            style: CenTheme.display(24,
                                letterSpacing: -0.2, height: 1.15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            S.kirimDesc,
                            style: CenTheme.body(
                              13,
                              color: CenTheme.sub,
                              weight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: wide ? 20 : 16),
                    formCard,
                    const SizedBox(height: 14),
                    noticeCard,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Fee preview that recalculates whenever the amount changes. The fee itself
/// comes from the node, the total is this transfer's amount plus that fee.
class _FeeSummary extends StatelessWidget {
  const _FeeSummary({
    required this.feePradha,
    required this.amountPradha,
    required this.loading,
    required this.failed,
  });

  final int? feePradha;
  final int amountPradha;
  final bool loading;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final fee = feePradha;
    final feeText = loading
        ? '…'
        : failed
            ? S.tidakTersedia
            : fee == null
                ? '—'
                : '${formatCen(fee)} CEN';
    final totalText = (fee == null || amountPradha <= 0)
        ? '—'
        : '${formatCen(amountPradha + fee)} CEN';

    Widget line(String label, String value, {bool emphasis = false}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: emphasis ? CenTheme.txt : CenTheme.sub,
                fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasis ? 14 : 12.5,
              color: emphasis ? CenTheme.txt : CenTheme.sub,
              fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CenTheme.bg1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CenTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(S.biayaJaringanPerkiraan, feeText),
          const SizedBox(height: 8),
          line(S.totalDipotong, totalText, emphasis: true),
          if (!loading && fee != null) ...[
            const SizedBox(height: 8),
            Text(
              S.feeFinalOtomatis,
              style: const TextStyle(
                fontSize: 11,
                color: CenTheme.muted,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
