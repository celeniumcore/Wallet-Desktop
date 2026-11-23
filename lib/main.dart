import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wallet_shell.dart';
import 'services/cen_wallet.dart';
import 'services/wallet_storage.dart';
import 'strings.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await S.load();
  try {
    await bip39Wordlist();
  } catch (_) {
    // Screens retry on demand; a missing asset must not block boot.
  }
  runApp(const CenApp());
}

class CenApp extends StatefulWidget {
  const CenApp({super.key});

  @override
  State<CenApp> createState() => _CenAppState();
}

class _CenAppState extends State<CenApp> {
  @override
  void initState() {
    super.initState();
    S.revision.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    S.revision.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: CenTheme.dark,
      home: const RootGate(),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

enum _Stage { splash, onboarding, login, pin, shell }

class _RootGateState extends State<RootGate> {
  _Stage _stage = _Stage.splash;
  CenWallet? _wallet;

  /// True while the onboarding screen was opened from the wallet picker.
  /// Drives the back button that returns to that picker.
  bool _onboardingFromLogin = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Short splash for branding, then decide the route.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final hasAny = await WalletStorage.hasAnyWallet();
    if (!mounted) return;

    if (!hasAny) {
      setState(() => _stage = _Stage.onboarding);
      return;
    }

    final mnemonic = await WalletStorage.loadMnemonic();
    if (mnemonic == null || mnemonic.isEmpty) {
      // Wallets exist but none is open: this is the post-logout state.
      if (!mounted) return;
      setState(() => _stage = _Stage.login);
      return;
    }

    try {
      final w = CenWallet.fromMnemonic(
          Mnemonic.fromPhrase(mnemonic),
          CenNetwork.mainnet,
        );
      await WalletStorage.migrateLegacyWallet(w.address);
      final hasPin = await WalletStorage.hasPin();
      if (!mounted) return;
      setState(() {
        _wallet = w;
        _stage = hasPin ? _Stage.pin : _Stage.shell;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _stage = _Stage.onboarding);
    }
  }

  /// A wallet the user just created or imported opens directly. The recovery
  /// phrase was entered on this screen, so a PIN gate here would only repeat a
  /// check the user already passed.
  void _afterOnboarding(CenWallet w, String mnemonic) {
    setState(() {
      _wallet = w;
      _onboardingFromLogin = false;
      _stage = _Stage.shell;
    });
  }

  /// Reopening a saved wallet goes through the PIN when one is configured.
  Future<void> _afterLogin(CenWallet w, String mnemonic) async {
    final hasPin = await WalletStorage.hasPin();
    if (!mounted) return;
    setState(() {
      _wallet = w;
      _stage = hasPin ? _Stage.pin : _Stage.shell;
    });
  }

  void _startCreateWallet() {
    setState(() {
      _onboardingFromLogin = true;
      _stage = _Stage.onboarding;
    });
  }

  void _backToWalletPicker() {
    setState(() {
      _onboardingFromLogin = false;
      _stage = _Stage.login;
    });
  }

  /// Locks the current wallet without deleting it; the login screen can reopen
  /// it or restore another one from its recovery phrase.
  Future<void> _logout() async {
    await WalletStorage.forgetActiveWallet();
    if (!mounted) return;
    setState(() {
      _wallet = null;
      _stage = _Stage.login;
    });
  }

  Future<void> _afterPinOk() async {
    // Wallet was already loaded before PIN gate if it existed; if not, load it.
    if (_wallet == null) {
      final mnemonic = await WalletStorage.loadMnemonic();
      if (mnemonic != null && mnemonic.isNotEmpty) {
        try {
          final w = CenWallet.fromMnemonic(
          Mnemonic.fromPhrase(mnemonic),
          CenNetwork.mainnet,
        );
          if (!mounted) return;
          setState(() {
            _wallet = w;
            _stage = _Stage.shell;
          });
          return;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _stage = _Stage.onboarding);
      return;
    }
    if (!mounted) return;
    setState(() => _stage = _Stage.shell);
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.splash:
        return const SplashScreen();
      case _Stage.onboarding:
        return OnboardingScreen(
          onDone: _afterOnboarding,
          onBack: _onboardingFromLogin ? _backToWalletPicker : null,
        );
      case _Stage.login:
        return LoginScreen(
          onDone: _afterLogin,
          onCreateNew: _startCreateWallet,
        );
      case _Stage.pin:
        return PinScreen(onVerified: _afterPinOk);
      case _Stage.shell:
        final w = _wallet;
        if (w == null) return const SplashScreen();
        return WalletShell(wallet: w, onLogout: _logout);
    }
  }
}
