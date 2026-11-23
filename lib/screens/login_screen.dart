import 'package:flutter/material.dart';

import '../services/cen_wallet.dart';
import '../services/wallet_storage.dart';
import '../strings.dart';
import '../theme.dart';

/// Lets a user pick a saved wallet or sign in to another one with a recovery
/// phrase. Wallets stay on the device; this screen only selects which one is
/// active. It does not send key material anywhere.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onDone,
    required this.onCreateNew,
  });

  final void Function(CenWallet wallet, String mnemonicWords) onDone;

  /// Opens the onboarding flow's wallet step, keeping this picker as the
  /// screen the user returns to with the back button.
  final VoidCallback onCreateNew;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<StoredWallet> _wallets = const [];
  bool _loading = true;
  bool _opening = false;
  String? _error;
  final _importCtrl = TextEditingController();
  bool _showRestore = false;
  List<String>? _wordlist;

  @override
  void initState() {
    super.initState();
    _load();
    _loadWordlist();
  }

  Future<void> _loadWordlist() async {
    try {
      final words = await bip39Wordlist();
      if (!mounted) return;
      setState(() => _wordlist = words);
    } catch (e) {
      debugPrint('LoginScreen: wordlist load failed: $e');
    }
  }

  @override
  void dispose() {
    _importCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final wallets = await WalletStorage.listWallets();
    if (!mounted) return;
    setState(() {
      _wallets = wallets;
      _loading = false;
      _showRestore = wallets.isEmpty;
    });
  }

  Future<void> _openStored(StoredWallet entry) async {
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final mnemonic = await WalletStorage.mnemonicFor(entry.id);
      if (mnemonic == null || mnemonic.isEmpty) {
        throw Exception(S.restoreError);
      }
      final wallet = CenWallet.fromMnemonic(
        Mnemonic.fromPhrase(mnemonic),
        CenNetwork.mainnet,
      );
      await WalletStorage.setActiveWallet(entry.id);
      await WalletStorage.registerWallet(mnemonic, address: wallet.address, label: entry.label);
      if (!mounted) return;
      widget.onDone(wallet, mnemonic);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _restoreFromPhrase() async {
    final phrase = _importCtrl.text.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');
    if (phrase.isEmpty) {
      setState(() => _error = S.fraseKosong);
      return;
    }
    if (_wordlist == null) {
      setState(() => _error = S.errFrasaWordlist);
      return;
    }
    final check = checkPhrase(phrase, _wordlist!);
    if (!check.lengthOk) {
      setState(() => _error = S.errFrasaJumlah);
      return;
    }
    if (check.unknown.isNotEmpty) {
      setState(() => _error = S.errFrasaKataAsing(check.unknown.join(', ')));
      return;
    }
    if (check.badChecksum) {
      setState(() => _error = S.errFrasaChecksum);
      return;
    }
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final wallet = CenWallet.fromMnemonic(
        Mnemonic.fromPhrase(check.words.join(' ')),
        CenNetwork.mainnet,
      );
      await WalletStorage.registerWallet(
        check.words.join(' '),
        address: wallet.address,
        label: 'Wallet ${_wallets.length + 1}',
      );
      if (!mounted) return;
      widget.onDone(wallet, check.words.join(' '));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Image.asset(
                      'assets/cen_logo_rounded10.png',
                      width: 72,
                      height: 72,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    S.pilihDompet,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.pilihDompetSub,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CenTheme.sub, height: 1.45),
                  ),
                  const SizedBox(height: 28),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    if (_wallets.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CenTheme.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CenTheme.line),
                        ),
                        child: Text(
                          S.tidakAdaDompet,
                          style: const TextStyle(color: CenTheme.sub),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._wallets.map(_walletTile),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _opening ? null : () => setState(() => _showRestore = !_showRestore),
                      icon: Icon(_showRestore ? Icons.expand_less : Icons.add),
                      label: Text(S.pulihkanWallet),
                    ),
                    if (_showRestore) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CenTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: CenTheme.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(S.pulihkanSub, style: const TextStyle(color: CenTheme.sub, fontSize: 13)),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _importCtrl,
                              maxLines: 4,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: InputDecoration(hintText: S.importHint),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _opening ? null : _restoreFromPhrase,
                              child: _opening
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(S.masukDompet),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: const TextStyle(color: CenTheme.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _opening ? null : widget.onCreateNew,
                      child: Text(S.buatWalletBaru),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.loginNote,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: CenTheme.muted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _walletTile(StoredWallet entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: CenTheme.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _opening ? null : () => _openStored(entry),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CenTheme.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CenTheme.acid.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: CenTheme.acid),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        entry.shortAddress,
                        style: const TextStyle(
                          color: CenTheme.sub,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: CenTheme.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
