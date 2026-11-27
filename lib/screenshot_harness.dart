import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'screens/dompet_screen.dart';
import 'screens/kirim_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/riwayat_screen.dart';
import 'screens/scan_qr_screen.dart';
import 'screens/setelan_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/terima_screen.dart';
import 'screens/wallet_shell.dart';
import 'services/bridge_api_simple.dart';
import 'services/cen_wallet.dart';
import 'services/wallet_data.dart';
import 'strings.dart';
import 'theme.dart';

/// Dev-only entry point that renders every screen once and writes PNGs to
/// `screenshots/`. Run with:
///   flutter run -d linux -t lib/screenshot_harness.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    print('FLUTTER_ERROR ${details.exceptionAsString()}');
    previous?.call(details);
  };
  runApp(const _HarnessApp());
}

class _Shot {
  const _Shot(
    this.name,
    this.builder, {
    this.wait = const Duration(milliseconds: 1400),
    this.size = const Size(1280, 820),
  });
  final String name;
  final Widget Function() builder;
  final Duration wait;
  final Size size;
}

class _HarnessApp extends StatefulWidget {
  const _HarnessApp();

  @override
  State<_HarnessApp> createState() => _HarnessAppState();
}

class _HarnessAppState extends State<_HarnessApp> {
  final _boundary = GlobalKey();
  int _index = 0;

  late final CenWallet _wallet;
  late final BridgeApi _api;
  late final List<_Shot> _shots;

  @override
  void initState() {
    super.initState();
    const phrase =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    _wallet = CenWallet.fromMnemonic(Mnemonic.fromPhrase(phrase), CenNetwork.mainnet);
    _api = BridgeApi(baseUrl: 'https://celenium.web.id/api');
    _shots = <_Shot>[
      _Shot('01_bahasa_id', () {
        S.setLocale('id');
        S.previewChosen(false);
        return OnboardingScreen(onDone: (_, __) {});
      }),
      _Shot('02_bahasa_en', () {
        S.setLocale('en');
        S.previewChosen(false);
        return OnboardingScreen(onDone: (_, __) {});
      }),
      _Shot('03_onboarding_wallet', () {
        S.setLocale('id');
        S.previewChosen(true);
        return OnboardingScreen(onDone: (_, __) {});
      }),
      _Shot('04_pin', () {
        S.setLocale('id');
        return PinScreen(onVerified: () {});
      }),
      _Shot('05_dompet', () => WalletShell(wallet: _wallet, onLogout: () async {}),
          wait: const Duration(seconds: 5)),
      _Shot('06_kirim', () {
        S.setLocale('id');
        return _Frame(child: KirimScreen(wallet: _wallet, api: _api));
      }),
      _Shot('07_terima', () {
        S.setLocale('id');
        return _Frame(child: TerimaScreen(wallet: _wallet));
      }),
      _Shot('08_riwayat', () {
        S.setLocale('id');
        return _Frame(child: RiwayatScreen(wallet: _wallet, api: _api));
      }, wait: const Duration(seconds: 5)),
      _Shot('09_setelan', () {
        S.setLocale('id');
        return _Frame(child: SetelanScreen(wallet: _wallet, onLogout: () async {}));
      }),
      _Shot('10_scan_qr', () {
        S.setLocale('id');
        return _Frame(child: const ScanQrScreen());
      }),
      _Shot('11_dompet_en', () {
        S.setLocale('en');
        return _Frame(child: DompetScreen(wallet: _wallet, api: _api));
      }, wait: const Duration(seconds: 5)),
      _Shot('12_import_frasa', () {
        S.setLocale('id');
        S.previewChosen(true);
        return OnboardingScreen(onDone: (_, __) {}, initialImport: true);
      }),
      _Shot('13_splash', () => const SplashScreen()),
      _Shot('15_login_restore', () {
        S.setLocale('id');
        return LoginScreen(onDone: (_, __) {}, onCreateNew: () {});
      }),
      _Shot('16_onboarding_back', () {
        S.setLocale('id');
        S.previewChosen(true);
        return OnboardingScreen(onDone: (_, __) {}, onBack: () {});
      }),
      _Shot('14_mobile_dompet', () {
        S.setLocale('id');
        return WalletShell(
          wallet: _wallet,
          onLogout: () async {},
          api: _PreviewApi(),
          previewData: _previewData(),
        );
      }, wait: const Duration(seconds: 5), size: const Size(390, 844)),
    _Shot('20_menu_desktop', () {
        S.setLocale('id');
        return WalletShell(wallet: _wallet, onLogout: () async {});
      }, wait: const Duration(seconds: 13)),
      _Shot('21_dompet_desktop', () {
        S.setLocale('id');
        return _Frame(
          child: DompetScreen(
            wallet: _wallet,
            api: _PreviewApi(),
            previewData: _previewData(),
          ),
        );
      }, wait: const Duration(seconds: 13)),
      _Shot('22_dompet_en', () {
        S.setLocale('en');
        return _Frame(child: DompetScreen(wallet: _wallet, api: _api));
      }, wait: const Duration(seconds: 13)),
      // Design preview only: fixed balance, ledger and saved addresses so the
      // populated layout can be reviewed while the public node is unreachable.
      // Nothing here is used by the shipped app.
      _Shot('26_dompet_add_address', () {
        S.setLocale('id');
        return _Frame(
          child: DompetScreen(
            wallet: _wallet,
            api: _PreviewApi(),
            previewData: _previewData(),
            previewDialog: 'add',
          ),
        );
      }, wait: const Duration(seconds: 3)),
      _Shot('27_dompet_delete_address', () {
        S.setLocale('id');
        return _Frame(
          child: DompetScreen(
            wallet: _wallet,
            api: _PreviewApi(),
            previewData: _previewData(),
            previewDialog: 'delete',
          ),
        );
      }, wait: const Duration(seconds: 3)),
      _Shot('28_setelan_seed', () {
        S.setLocale('id');
        return _Frame(
          child: SetelanScreen(
            wallet: _wallet,
            onLogout: () async {},
            previewDialog: 'seed',
          ),
        );
      }, wait: const Duration(seconds: 3)),
      _Shot('29_setelan_pin', () {
        S.setLocale('id');
        return _Frame(
          child: SetelanScreen(
            wallet: _wallet,
            onLogout: () async {},
            previewDialog: 'pin',
          ),
        );
      }, wait: const Duration(seconds: 3)),
      _Shot('30_setelan_hapus_pin', () {
        S.setLocale('id');
        return _Frame(
          child: SetelanScreen(
            wallet: _wallet,
            onLogout: () async {},
            previewDialog: 'hapus_pin',
          ),
        );
      }, wait: const Duration(seconds: 3)),
      _Shot('31_setelan_logout', () {
        S.setLocale('id');
        return _Frame(
          child: SetelanScreen(
            wallet: _wallet,
            onLogout: () async {},
            previewDialog: 'logout',
          ),
        );
      }, wait: const Duration(seconds: 3)),
      _Shot('32_terima_shell', () {
        S.setLocale('id');
        return WalletShell(
          wallet: _wallet,
          onLogout: () async {},
          initialIndex: 2,
        );
      }, wait: const Duration(seconds: 6), size: const Size(1440, 900)),
      _Shot('23_dompet_preview', () {
        S.setLocale('id');
        return _Frame(
          child: DompetScreen(
            wallet: _wallet,
            api: _PreviewApi(),
            previewData: _previewData(),
          ),
        );
      }, wait: const Duration(seconds: 4)),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final only = Platform.environment['SHOT'];
    print('SHOT_RUN start total=${_shots.length} only=$only');
    for (var i = 0; i < _shots.length; i++) {
      if (only != null && only.isNotEmpty && !_shots[i].name.contains(only)) {
        continue;
      }
      setState(() => _index = i);
      await Future<void>.delayed(_shots[i].wait);
      print('SHOT_READY ${_shots[i].name}');
      await _capture(_shots[i].name);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    exit(0);
  }

  Future<void> _capture(String name) async {
    final obj = _boundary.currentContext?.findRenderObject();
    if (obj is! RenderRepaintBoundary) {
      print('SHOT_MISS $name');
      return;
    }
    final image = await obj.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final dir = Directory('screenshots');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    await File('screenshots/$name.png').writeAsBytes(bytes.buffer.asUint8List());
    // ignore: avoid_print
    print('SHOT $name ${image.width}x${image.height}');
  }

  @override
  Widget build(BuildContext context) {
    final shot = _shots[_index];
    // Pin every shot to a fixed logical canvas. The GTK window size depends on
    // the host compositor and would otherwise leave the layout floating inside
    // meters of empty background.
    return ColoredBox(
      color: const Color(0xFF050706),
      child: Center(
        child: RepaintBoundary(
          key: _boundary,
          child: SizedBox(
            width: shot.size.width,
            height: shot.size.height,
            child: MaterialApp(
              key: ValueKey(_index),
              debugShowCheckedModeBanner: false,
              theme: CenTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: shot.size,
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: child!,
              ),
              home: shot.builder(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps a bare page in the shell chrome-less scaffold used inside the app.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: CenTheme.bg, body: child);
  }
}


/// Harness-only bridge stub. Returns a fixed balance/fee so the populated
/// layout renders without a reachable node; never constructed by the app.
class _PreviewApi extends BridgeApi {
  _PreviewApi() : super(baseUrl: 'https://celenium.web.id/api');

  @override
  Future<int> fetchBalance(String address) async => 12840620000;

  @override
  Future<int> fetchFee() async => 1000000;
}

/// Harness-only ledger used by the "preview" shot: a rising 30-day chart plus
/// five rows, so spacing and alignment can be judged against the 20 Nov board.
WalletData _previewData() {
  final now = DateTime.now();
  int pradha(double cen) => (cen * 100000000).round();

  final samples = <BalanceSample>[
    for (var day = 29; day >= 0; day--)
      BalanceSample(
        time: now.subtract(Duration(days: day)),
        pradha: pradha(96420.4 + (29 - day) * 620.5 + ((day * 37) % 11) * 95.4),
      ),
  ];

  return WalletData(
    lastBalance: 12840620000,
    samples: samples,
    entries: <LedgerEntry>[
      LedgerEntry(
        id: 'e1',
        incoming: true,
        amountPradha: pradha(4200),
        time: now.subtract(const Duration(hours: 2, minutes: 14)),
        counterparty: 'cen69:qzv8pv7f2w9kd3n5x6t0m4rj7ls8hy2gc5ab3de6fk9mn2pq4rs7tu5vw8xz',
        txid: '9f3c1ab77e0d4c58a2b6f19d3e74c0a8b5d21e6f9a4c7b3d8e0f2a5c6b7d8e9f',
      ),
      LedgerEntry(
        id: 'e2',
        incoming: false,
        amountPradha: pradha(1250),
        time: now.subtract(const Duration(hours: 9, minutes: 41)),
        counterparty: 'cen69:qzr4kn8t2v6x0m5p9s3d7f1g4h8j2l6n0q5w9e3r7t1y5u9i3o7a2s6d0f4g8h',
        txid: '3a7e5d1c9b2f84670d3e5a7c9b1f2d4e6a8c0b3d5f7e9a1c2b4d6f8e0a2c4b6d',
      ),
      LedgerEntry(
        id: 'e3',
        incoming: true,
        amountPradha: pradha(860.55),
        time: now.subtract(const Duration(days: 1, hours: 3)),
        counterparty: 'cen69:qz8m3n6b1v4c7x0z5l9k2j5h8g1f4d7s0a3p6o9i2u5y8t1r4e7w0q3z6x9c2v5b',
        txid: 'b41d7f9a2c6e8b0d4f6a8c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d',
      ),
      LedgerEntry(
        id: 'e4',
        incoming: false,
        amountPradha: pradha(340),
        time: now.subtract(const Duration(days: 2, hours: 7)),
        counterparty: 'cen69:qk2w5e8r1t4y7u0i3o6p9a2s5d8f1g4h7j0k3l6z9x2c5v8b1n4m7q0w3e6r9t2y5',
        txid: '7d2a9c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2b4d6f8a0c2e4b6d8f0a2c',
      ),
      LedgerEntry(
        id: 'e5',
        incoming: true,
        amountPradha: pradha(2100),
        time: now.subtract(const Duration(days: 4, hours: 1)),
        counterparty: 'cen69:qz3n6c9v2b5m8k1j4h7g0f3d6s9a2p5o8i1u4y7t0r3e6w9q2z5x8c1v4b7n0m3k6j',
        txid: 'c58e0a2c4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2b4d6f8a0c2',
      ),
    ],
    addresses: <SavedAddress>[
      SavedAddress(
        id: 'a1',
        label: 'Kantor',
        address: 'cen69:qz4m7n0b3v6c9x2z5l8k1j4h7g0f3d6s9a2p5o8i1u4y7t0r3e6w9q2z5x8c1v4b7n0m3k6j',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      SavedAddress(
        id: 'a2',
        label: 'Tabungan',
        address: 'cen69:qz7h2j5k8l1m4n7b0v3c6x9z2a5s8d1f4g7h0j3k6l9n2m5b8v1c4x7z0a3s6d9f2g5h8j',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ],
  );
}
