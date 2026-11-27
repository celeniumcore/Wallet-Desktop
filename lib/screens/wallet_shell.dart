import 'dart:async';

import 'package:flutter/material.dart';

import '../services/bridge_api_simple.dart';
import '../services/cen_wallet.dart';
import '../services/wallet_data.dart';
import '../strings.dart';
import '../theme.dart';
import 'dompet_screen.dart';
import 'kirim_screen.dart';
import 'riwayat_screen.dart';
import 'setelan_screen.dart';
import 'terima_screen.dart';

const String _version = 'v1.0.3';

/// Frame around the five wallet pages: sidebar on desktop, bottom bar on
/// narrow windows. Sign-out lives in Settings, next to the other account-level
/// actions, so it is not one stray click away while switching pages.
class WalletShell extends StatefulWidget {
  const WalletShell({
    super.key,
    required this.wallet,
    required this.onLogout,
    this.api,
    this.previewData,
    this.initialIndex = 0,
  });

  final CenWallet wallet;
  final Future<void> Function() onLogout;

  /// Test seam; the app builds its own bridge client.
  final BridgeApi? api;

  /// Harness/test fixture for the wallet page; the shipped app leaves it null.
  final WalletData? previewData;

  /// Harness/test seam so a screenshot can open on a given tab. The app
  /// always starts on the wallet page.
  final int initialIndex;

  @override
  State<WalletShell> createState() => _WalletShellState();
}

class _WalletShellState extends State<WalletShell> {
  late int _index = widget.initialIndex;
  late final BridgeApi _api;

  /// Recipient carried from the wallet page into the send tab. Cleared whenever
  /// the send tab is opened from navigation, so an old prefill never sticks.
  String? _kirimRecipient;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? BridgeApi(baseUrl: 'https://celenium.web.id/api');
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTab(int i) {
    setState(() {
      _index = i;
      if (i == 1) _kirimRecipient = null;
    });
  }

  void _openKirim(String? recipient) {
    setState(() {
      _kirimRecipient = recipient;
      _index = 1;
    });
  }

  Widget _page(int index) {
    switch (index) {
      case 1:
        return KirimScreen(
          key: ValueKey<String?>(_kirimRecipient),
          wallet: widget.wallet,
          api: _api,
          initialRecipient: _kirimRecipient,
        );
      case 2:
        return TerimaScreen(wallet: widget.wallet);
      case 3:
        return RiwayatScreen(wallet: widget.wallet, api: _api);
      case 4:
        return SetelanScreen(wallet: widget.wallet, onLogout: widget.onLogout);
      case 0:
      default:
        return DompetScreen(
          wallet: widget.wallet,
          api: _api,
          onOpenTab: _onTab,
          onSend: _openKirim,
          previewData: widget.previewData,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final wide = width >= 900;

    return Scaffold(
      backgroundColor: CenTheme.bg,
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  _Sidebar(
                    index: _index,
                    onSelect: _onTab,
                  ),
                  Expanded(child: _page(_index)),
                ],
              )
            : _page(_index),
      ),
      bottomNavigationBar: wide
          ? null
          : _BottomBar(index: _index, onSelect: _onTab),
    );
  }
}

class _NavEntry {
  const _NavEntry(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

List<_NavEntry> _navEntries() => <_NavEntry>[
  _NavEntry(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, S.dompet),
  _NavEntry(Icons.north_east_rounded, Icons.north_east_rounded, S.kirim),
  _NavEntry(Icons.south_west_rounded, Icons.south_west_rounded, S.terima),
  _NavEntry(Icons.receipt_long_outlined, Icons.receipt_long_rounded, S.riwayat),
  _NavEntry(Icons.settings_outlined, Icons.settings_rounded, S.setelan),
];

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.index,
    required this.onSelect,
  });

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final entries = _navEntries();
    return Container(
      width: 222,
      decoration: const BoxDecoration(
        color: CenTheme.bg1,
        border: Border(right: BorderSide(color: CenTheme.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 26, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/cen_logo_circle.png',
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Padding(
                      // 5 px drops the 16 px brand baseline onto the 24 px
                      // page heading's baseline (7 sat 2 px low, measured).
                      padding: const EdgeInsets.only(top: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CenTheme.display(16, letterSpacing: 0.2),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            S.nonKustodial,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CenTheme.body(10.5, color: CenTheme.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _SidebarGroup(S.utama),
                  for (var i = 0; i < 3; i++)
                    _SidebarItem(
                      label: entries[i].label,
                      active: index == i,
                      onTap: () => onSelect(i),
                    ),
                  const SizedBox(height: 18),
                  _SidebarGroup(S.lainnya),
                  for (var i = 3; i < entries.length; i++)
                    _SidebarItem(
                      label: entries[i].label,
                      active: index == i,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Text(
                'v$_version',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CenTheme.body(10.5, color: CenTheme.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarGroup extends StatelessWidget {
  const _SidebarGroup(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: Text(
        label.toUpperCase(),
        style: CenTheme.body(
          10,
          color: CenTheme.muted,
          letterSpacing: 1.1,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? CenTheme.acid.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withValues(alpha: 0.03),
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // The 8px marker slot stays reserved when inactive so the
                  // label never shifts as the selection moves.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? CenTheme.acid : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CenTheme.body(
                        13.5,
                        color: active ? CenTheme.acid : CenTheme.sub,
                        weight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CenTheme.bg1,
        border: Border(top: BorderSide(color: CenTheme.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < _navEntries().length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelect(i),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            index == i
                                ? _navEntries()[i].selectedIcon
                                : _navEntries()[i].icon,
                            size: 19,
                            color: index == i ? CenTheme.acid : CenTheme.sub,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _navEntries()[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: index == i ? CenTheme.txt : CenTheme.sub,
                              fontSize: 9.5,
                              fontWeight:
                                  index == i ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}