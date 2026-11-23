import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../strings.dart';
import '../services/cen_wallet.dart';
import '../services/wallet_storage.dart';
import '../services/biometric_service.dart';

class SetelanScreen extends StatefulWidget {
  const SetelanScreen({super.key, required this.wallet, required this.onLogout});
  final CenWallet wallet;
  final Future<void> Function() onLogout;

  @override
  State<SetelanScreen> createState() => _SetelanScreenState();
}

class _SetelanScreenState extends State<SetelanScreen> {
  bool _hasPin = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _biometricLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecurity();
  }

  Future<void> _loadSecurity() async {
    final hasPin = await WalletStorage.hasPin();
    final bioEnabled = await WalletStorage.loadBiometric();
    final bioAvail = await BiometricService.instance.isAvailable();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricEnabled = bioEnabled;
      _biometricAvailable = bioAvail;
      _biometricLoading = false;
    });
  }

  void _showSeed() async {
    final mnemonic = await WalletStorage.loadMnemonic();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CenTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(S.frasaPemulihan,
            style: TextStyle(color: CenTheme.txt, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CenTheme.elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CenTheme.line),
              ),
              child: Text(
                mnemonic ?? S.frasaTidakAda,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: CenTheme.txt,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              S.frasaWarn,
              style: const TextStyle(
                  fontSize: 12.5, color: CenTheme.red, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mnemonic != null) {
                Clipboard.setData(ClipboardData(text: mnemonic));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.frasaDisalin)),
                );
              }
            },
            child: Text(S.salin, style: TextStyle(color: CenTheme.acid)),
          ),
          FilledButton(
            style: CenTheme.primaryBtn,
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.tutup),
          ),
        ],
      ),
    );
  }

  Future<void> _setPin() async {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? err;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: CenTheme.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            _hasPin ? S.ubahPIN : S.buatPIN,
            style: const TextStyle(color: CenTheme.txt, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.pinDesc,
                style: const TextStyle(
                    fontSize: 12.5, color: CenTheme.sub, height: 1.5),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _pinInputDecoration(S.pinBaru),
                style: const TextStyle(color: CenTheme.txt, letterSpacing: 4),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _pinInputDecoration(S.konfirmasiPIN),
                style: const TextStyle(color: CenTheme.txt, letterSpacing: 4),
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!,
                    style:
                        const TextStyle(color: CenTheme.red, fontSize: 12.5)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.batal, style: TextStyle(color: CenTheme.sub)),
            ),
            FilledButton(
              style: CenTheme.primaryBtn,
              onPressed: () async {
                final p = pinCtrl.text.trim();
                final c = confirmCtrl.text.trim();
                if (p.length < 4) {
                  setD(() => err = 'PIN minimal 4 digit');
                  return;
                }
                if (p != c) {
                  setD(() => err = S.pinTidakCocok);
                  return;
                }
                await WalletStorage.savePin(p);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: Text(S.simpan),
            ),
          ],
        ),
      ),
    );
    pinCtrl.dispose();
    confirmCtrl.dispose();
    if (result == true) {
      await _loadSecurity();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.pinTersimpan)),
        );
      }
    }
  }

  InputDecoration _pinInputDecoration(String hint) {
    return InputDecoration(
      counterText: '',
      hintText: hint,
      hintStyle: const TextStyle(color: CenTheme.muted, letterSpacing: 0),
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
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      if (!_hasPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  S.biometrikButuhPIN)),
        );
        return;
      }
      if (!_biometricAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.biometrikTidakTersedia)),
        );
        return;
      }
      final ok = await BiometricService.instance.authenticate(
        reason: S.biometrikVerifikasi,
      );
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.biometrikGagal)),
          );
        }
        return;
      }
      await WalletStorage.saveBiometric(true);
    } else {
      await WalletStorage.saveBiometric(false);
    }
    await _loadSecurity();
  }

  Future<void> _removePin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CenTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(S.hapusPINJudul, style: TextStyle(color: CenTheme.txt)),
        content: Text(
          S.hapusPinWarning,
          style: TextStyle(color: CenTheme.sub, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  Text(S.batal, style: TextStyle(color: CenTheme.sub))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CenTheme.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.hapus),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await WalletStorage.clearPin();
      await WalletStorage.saveBiometric(false);
      await _loadSecurity();
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CenTheme.card,
        title: Text(S.keluarKonfirmasiJudul, style: const TextStyle(color: CenTheme.txt)),
        content: Text(S.keluarKonfirmasiMsg, style: const TextStyle(color: CenTheme.sub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.batal, style: const TextStyle(color: CenTheme.sub)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CenTheme.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.yaKeluar),
          ),
        ],
      ),
    );
    if (ok == true) await widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.setelan,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: CenTheme.txt),
          ),
          const SizedBox(height: 20),
          _card([
            _sectionLabel(S.dompet),
            _row(
              S.alamat,
              _short(widget.wallet.address),
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded,
                    size: 18, color: CenTheme.sub),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.wallet.address));
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.alamatDisalin)));
                },
              ),
            ),
            _row(
              S.frasaPemulihan,
              _hasPin ? S.terlindungiPin : S.belumAdaPin,
              trailing: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: CenTheme.elevated,
                  foregroundColor: CenTheme.txt,
                ),
                onPressed: _showSeed,
                child: Text(S.lihat, style: TextStyle(fontSize: 12.5)),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _card([
            _sectionLabel(S.keamanan),
            _row(
              S.pinDompet,
              _hasPin ? S.aktif : S.belumDiatur,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasPin)
                    IconButton(
                      tooltip: S.hapusPIN,
                      onPressed: _removePin,
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: CenTheme.sub),
                    ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: CenTheme.elevated,
                      foregroundColor: CenTheme.txt,
                    ),
                    onPressed: _setPin,
                    child: Text(_hasPin ? S.ubah : S.buat,
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: CenTheme.elevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fingerprint,
                        color: CenTheme.acid, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(S.biometrikBuka,
                            style: TextStyle(
                                fontSize: 14,
                                color: CenTheme.txt,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 3),
                        Text(
                          _biometricLoading
                              ? S.biometrikCek
                              : !_biometricAvailable
                                  ? S.biometrikNonaktif
                                  : !_hasPin
                                      ? S.biometrikButuhPIN2
                                      : S.biometrikDesc,
                          style: const TextStyle(
                              fontSize: 12, color: CenTheme.sub, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _biometricEnabled && _hasPin && _biometricAvailable,
                    onChanged: (_biometricLoading || !_biometricAvailable)
                        ? null
                        : _toggleBiometric,
                    activeThumbColor: CenTheme.acid,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                S.biometrikCatatan,
                style: TextStyle(
                    fontSize: 11.5, color: CenTheme.muted, height: 1.5),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _card([
            _sectionLabel(S.jaringan),
            _row(S.node, S.jaringanAuto,
                trailing: Text(S.auto,
                    style: const TextStyle(color: CenTheme.sub, fontSize: 12.5))),
            _sectionLabel(S.bahasa),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _LangChip(
                      label: S.bahasaIndonesia,
                      selected: S.isId,
                      onTap: () async {
                        await S.pick('id');
                        if (!mounted) return;
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LangChip(
                      label: S.bahasaInggris,
                      selected: !S.isId,
                      onTap: () async {
                        await S.pick('en');
                        if (!mounted) return;
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _card([
            _sectionLabel(S.akun),
            _row(
              S.keluarAkun,
              S.keluarAkunDesc,
              trailing: OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: Text(S.keluarAkun),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CenTheme.red,
                  side: BorderSide(color: CenTheme.red.withValues(alpha: 0.45)),
                  textStyle: const TextStyle(fontSize: 12.5),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _card([
            _sectionLabel(S.tentang),
            _row(S.aplikasi, S.aplikasiNama,
                trailing: const SizedBox.shrink()),
            _row(S.versiLabel, S.appVersion, trailing: const SizedBox.shrink()),
            _row(S.jaringan, 'CEN mainnet', trailing: const SizedBox.shrink()),
          ]),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _short(String addr) {
    if (addr.length <= 20) return addr;
    return '${addr.substring(0, 12)}...${addr.substring(addr.length - 8)}';
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CenTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CenTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: CenTheme.muted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _row(String label, String sub, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        color: CenTheme.txt,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(fontSize: 12, color: CenTheme.sub)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}


class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? CenTheme.acid.withValues(alpha: 0.12) : CenTheme.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? CenTheme.acid : CenTheme.line, width: selected ? 1.4 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: selected ? CenTheme.acid : CenTheme.muted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? CenTheme.acid : CenTheme.txt,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
