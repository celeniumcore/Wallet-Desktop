import 'package:flutter/material.dart';
import '../theme.dart';
import '../strings.dart';
import '../services/cen_wallet.dart';
import '../services/wallet_storage.dart';
import '../widgets/cen_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onDone,
    this.onBack,
    this.initialImport = false,
  });
  final void Function(CenWallet wallet, String mnemonicWords) onDone;

  /// Present when the screen was opened from the wallet picker; renders a back
  /// button that returns there.
  final VoidCallback? onBack;

  /// Preview hook: open straight on the import form.
  final bool initialImport;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late bool _showImport = widget.initialImport;
  late bool _langDone = S.chosen;
  bool _creating = false;
  List<String>? _wordlist;
  final _importCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWordlist();
  }

  @override
  void dispose() {
    _importCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWordlist() async {
    try {
      final words = await bip39Wordlist();
      if (!mounted) return;
      setState(() => _wordlist = words);
    } catch (_) {}
  }

  Future<void> _pickLanguage(String locale) async {
    await S.pick(locale);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _createWallet() async {
    if (_wordlist == null || _creating) return;
    setState(() => _creating = true);
    try {
      final mnemonic = generateMnemonic(wordlist: _wordlist!);
      final wallet = CenWallet.fromMnemonic(mnemonic, CenNetwork.mainnet);
      await WalletStorage.registerWallet(mnemonic.phrase, address: wallet.address);
      if (!mounted) return;
      widget.onDone(wallet, mnemonic.phrase);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.errBuatWallet(e))));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _importWallet() async {
    if (_wordlist == null || _creating) return;
    final check = checkPhrase(_importCtrl.text, _wordlist!);
    if (!check.lengthOk) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.errFrasaJumlah)));
      return;
    }
    if (check.unknown.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.errFrasaKataAsing(check.unknown.join(', ')))));
      return;
    }
    if (check.badChecksum) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.errFrasaChecksum)));
      return;
    }
    setState(() => _creating = true);
    try {
      final phrase = check.words.join(' ');
      final mnemonic = Mnemonic.fromPhrase(phrase);
      final wallet = CenWallet.fromMnemonic(mnemonic, CenNetwork.mainnet);
      await WalletStorage.registerWallet(phrase, address: wallet.address);
      if (!mounted) return;
      widget.onDone(wallet, phrase);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.errFrasaTidakValid(e))));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Widget _languageTile({
    required String locale,
    required String title,
    required String subtitle,
  }) {
    final selected = S.locale == locale;
    return InkWell(
      onTap: () => _pickLanguage(locale),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? CenTheme.acid.withValues(alpha: 0.10) : CenTheme.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? CenTheme.acid : CenTheme.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? CenTheme.acid : CenTheme.txt,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: CenTheme.muted),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? CenTheme.acid : CenTheme.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: CenTheme.acid.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.language, color: CenTheme.acid, size: 28),
        ),
        const SizedBox(height: 20),
        Text(
          S.pilihBahasa,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: CenTheme.txt,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          S.pilihBahasaSub,
          style: const TextStyle(fontSize: 13, height: 1.6, color: CenTheme.muted),
        ),
        const SizedBox(height: 24),
        _languageTile(
          locale: 'id',
          title: S.bahasaIndonesia,
          subtitle: S.bahasaInduk,
        ),
        const SizedBox(height: 10),
        _languageTile(
          locale: 'en',
          title: S.bahasaInggris,
          subtitle: S.bahasaInggrisInduk,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: FilledButton(
            style: CenTheme.primaryBtn,
            onPressed: () {
              // Advance immediately; persisting the choice must not gate the UI.
              setState(() => _langDone = true);
              S.pick(S.locale);
            },
            child: Text(S.lanjut),
          ),
        ),
      ],
    );
  }

  Widget _walletStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CenLogo(size: 88),
        const SizedBox(height: 20),
        const Text(
          'CEN Wallet',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: CenTheme.txt,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          S.onboardingTagline,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, height: 1.6, color: CenTheme.muted),
        ),
        const SizedBox(height: 36),
        if (!_showImport) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: CenTheme.primaryBtn,
              onPressed: _creating ? null : _createWallet,
              child: _creating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: CenTheme.bg),
                    )
                  : Text(S.buatWalletBaru),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: CenTheme.txt,
                side: const BorderSide(color: CenTheme.lineStrong),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => _showImport = true),
              child: Text(S.imporFrasa),
            ),
          ),
        ] else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              S.labelFrasa,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: CenTheme.muted),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _importCtrl,
            maxLines: 4,
            style: const TextStyle(
                fontSize: 13, color: CenTheme.txt, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'word1 word2 word3 ...',
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
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              style: CenTheme.primaryBtn,
              onPressed: _creating ? null : _importWallet,
              child: _creating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: CenTheme.bg),
                    )
                  : Text(S.impor),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => setState(() => _showImport = false),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: Text(S.kembaliKePilihan),
          ),
        ],
        const SizedBox(height: 28),
        Text(
          S.onboardingNote,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, height: 1.5, color: CenTheme.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Language is chosen before any wallet creation/import action.
    final showLanguage = !_langDone;
    return Scaffold(
      backgroundColor: CenTheme.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              decoration: BoxDecoration(
                color: CenTheme.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: CenTheme.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.onBack != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(S.kembali),
                        style: TextButton.styleFrom(
                          foregroundColor: CenTheme.sub,
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: showLanguage
                        ? KeyedSubtree(
                            key: const ValueKey('lang'),
                            child: _languageStep(),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('wallet'),
                            child: _walletStep(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
