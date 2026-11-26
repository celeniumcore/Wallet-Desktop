import 'dart:async';
import 'package:flutter/material.dart';

import '../format.dart';
import '../services/bridge_api_simple.dart';
import '../services/cen_wallet.dart';
import '../services/wallet_data.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/cen_logo.dart';
import '../widgets/empty_panel.dart';
import '../widgets/sparkline_chart.dart';

/// Dashboard. Every number, row, and chart point comes from the node or from
/// this device's own ledger file — nothing is seeded for the screenshot.
class DompetScreen extends StatefulWidget {
  const DompetScreen({
    super.key,
    required this.wallet,
    required this.api,
    this.onOpenTab,
    this.onSend,
    this.previewData,
    this.previewDialog,
  });

  final CenWallet wallet;
  final BridgeApi api;
  final ValueChanged<int>? onOpenTab;

  /// Opens the shell's send tab. Kept as a callback so the wallet page never
  /// pushes a second copy of the send form.
  final ValueChanged<String?>? onSend;

  /// Harness-only fixture. When set, the page renders this ledger instead of
  /// the on-device file; the shipped app always leaves it null.
  final WalletData? previewData;

  /// Harness-only: opens a dialog on first frame for screenshot coverage.
  final String? previewDialog;

  @override
  State<DompetScreen> createState() => _DompetScreenState();
}

class _DompetScreenState extends State<DompetScreen> {
  static const String _genesisPrefix = 'c7ad53d3';
  static const List<int> _ranges = <int>[7, 30, 90];

  int _balance = -1;
  int? _feePradha;
  bool _nodeOffline = false;
  bool _loading = true;
  WalletData? _data;
  int _rangeDays = 30;
  Timer? _poll;

  String get _address => widget.wallet.address;
  WalletData get _store => _data ?? WalletData();

  @override
  void initState() {
    super.initState();
    _boot();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
    if (widget.previewDialog != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        if (widget.previewDialog == 'add') {
          await _addAddress();
        } else if (widget.previewDialog == 'delete') {
          await _removeAddress(
            SavedAddress(
              id: 'preview',
              label: 'Kantor',
              address: 'cen69:qz4m7n0b3v6c9x2z5l8k1j4h7g0f3d6s9a2p5o8i1u4y7t0r3e6w9q2z5x8c1v4b7n0m3k6j',
              createdAt: DateTime.now(),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    final data =
        widget.previewData ?? await WalletDataStore.load(_address);
    if (!mounted) return;
    // Stay in the loading state until the first balance read settles, so the
    // header cannot claim "Sinkron" while the card still says "—".
    setState(() => _data = data);
    await _refresh();
  }

  Future<void> _onRefresh() async {
    setState(() => _loading = true);
    await _refresh();
    if (mounted && _loading) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    try {
      final balance = await widget.api.fetchBalance(_address);
      int? fee;
      try {
        fee = await widget.api.fetchFee();
      } catch (_) {
        fee = null;
      }
      final data = _data ?? await WalletDataStore.load(_address);
      final changed = data.observeBalance(balance, DateTime.now());
      if (changed && widget.previewData == null) {
        await WalletDataStore.save(_address, data);
      }
      if (!mounted) return;
      setState(() {
        _data = data;
        _balance = balance;
        _nodeOffline = false;
        _loading = false;
        if (fee != null) _feePradha = fee;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nodeOffline = true;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final data = _data;
    if (data == null) return;
    await WalletDataStore.save(_address, data);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        // The balance chart only floats right when the card can hold the full
        // 52px figure beside it; below that it stacks under the actions.
        final inlineChart = constraints.maxWidth < 980;
        final pad = wide ? 34.0 : 16.0;

        final body = wide ? _wideBody(inlineChart) : _narrowBody(inlineChart);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, wide ? 26 : 18, pad, 26),
          child: body,
        );
      },
    );
  }

  Widget _wideBody(bool inlineChart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 18),
        _balanceCard(inlineChart: inlineChart),
        const SizedBox(height: 22),
        // Layout kembali berdampingan: Aktivitas kiri, kolom info kanan.
        // Card Aktivitas dibuat lebih panjang agar mengisi ruang bawah yang kosong.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _activityCard(stretch: true)),
              const SizedBox(width: 20),
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    _addressCard(),
                    const SizedBox(height: 14),
                    _backupCard(),
                    const SizedBox(height: 14),
                    _diagnosticsCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _narrowBody(bool inlineChart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 16),
        _balanceCard(inlineChart: inlineChart),
        const SizedBox(height: 14),
        _activityCard(),
        const SizedBox(height: 14),
        _addressCard(),
        const SizedBox(height: 14),
        _backupCard(),
        const SizedBox(height: 14),
        _diagnosticsCard(),
      ],
    );
  }

  Widget _header() {
    // A balance that never arrived is "loading", not "synced" — the node can
    // be reachable while the first read is still in flight.
    final pending = _loading || (_balance < 0 && !_nodeOffline);
    final status = _nodeOffline ? S.terputus : (pending ? S.memuat : S.sinkron);
    final dot = _nodeOffline
        ? CenTheme.red
        : (pending ? CenTheme.muted : CenTheme.green);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.dompet,
                style: CenTheme.display(24, letterSpacing: -0.2, height: 1.15),
              ),
              const SizedBox(height: 4),
              Text(
                S.dompetSub,
                style: CenTheme.body(11.5, color: CenTheme.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dot,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: dot.withValues(alpha: 0.45),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Mainnet · $status',
                style: CenTheme.body(11.5, color: CenTheme.sub),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 30,
                height: 30,
                child: IconButton(
                  onPressed: _loading ? null : _onRefresh,
                  tooltip: S.muatUlang,
                  padding: EdgeInsets.zero,
                  iconSize: 15,
                  color: CenTheme.muted,
                  disabledColor: CenTheme.line,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _balanceCard({required bool inlineChart}) {
    final raw = _balance < 0 ? null : _balance;
    final amount = raw == null ? '—' : formatCen(raw);
    final chartOnRight = !inlineChart;
    final busy = _loading && raw == null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: BoxDecoration(
          color: CenTheme.bg1,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: CenTheme.line),
        ),
        child: Stack(
          children: [
            // Watermark of the same mark used in the sidebar; it only anchors
            // the card's empty right corner, so it stays under 6% opacity.
            Positioned(
              right: -34,
              bottom: -52,
              child: IgnorePointer(
                child: CenLogo(size: 230, opacity: 0.05),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: _corner(top: true),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: _corner(top: false),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(30, 24, chartOnRight ? 360 : 30, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.saldoTersedia,
                    style: CenTheme.body(
                      10.5,
                      color: CenTheme.muted,
                      letterSpacing: 1.2,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          busy ? '…' : amount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CenTheme.display(
                            50,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CEN',
                        style: CenTheme.display(
                          22,
                          weight: FontWeight.w600,
                          color: CenTheme.sub,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    raw == null ? '—' : formatRawPradha(raw),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CenTheme.mono(11.5, color: CenTheme.muted),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _primaryAction(
                        S.kirim,
                        Icons.north_east_rounded,
                        _nodeOffline || raw == null ? null : () => widget.onSend?.call(null),
                      ),
                      const SizedBox(width: 10),
                      _secondaryAction(
                        S.terima,
                        Icons.south_west_rounded,
                        () => widget.onOpenTab?.call(2),
                      ),
                    ],
                  ),
                  if (inlineChart) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: CenTheme.line),
                    const SizedBox(height: 14),
                    _chartBlock(height: 76),
                  ],
                ],
              ),
            ),
            if (chartOnRight)
              Positioned(
                right: 26,
                top: 22,
                width: 330,
                child: _chartBlock(height: 96),
              ),
          ],
        ),
      ),
    );
  }

  /// L-shaped acid mark in opposite corners of the balance card.
  Widget _corner({required bool top}) {
    const ink = Color(0x59C9D98F);
    const side = BorderSide(color: ink, width: 1.5);
    return SizedBox(
      width: 13,
      height: 13,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top ? side : BorderSide.none,
            left: top ? side : BorderSide.none,
            bottom: top ? BorderSide.none : side,
            right: top ? BorderSide.none : side,
          ),
        ),
      ),
    );
  }

  Widget _chartBlock({required double height}) {
    final samples = _store.samplesWithin(Duration(days: _rangeDays), DateTime.now());
    final enough = samples.length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$_rangeDays ${S.hariTerakhir}',
                style: const TextStyle(color: CenTheme.muted, fontSize: 10.5),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: CenTheme.bg1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CenTheme.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final days in _ranges)
                    GestureDetector(
                      onTap: () => setState(() => _rangeDays = days),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 34,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _rangeDays == days
                              ? CenTheme.acid.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${days}d',
                          style: TextStyle(
                            color: _rangeDays == days ? CenTheme.acid : CenTheme.muted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: enough ? height : height * 0.55,
          child: enough ? SparklineChart(samples: samples) : _chartEmpty(),
        ),
      ],
    );
  }

  Widget _chartEmpty() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CenTheme.line.withValues(alpha: 0.7)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.show_chart_rounded, size: 13, color: CenTheme.muted),
              const SizedBox(width: 5),
              Text(
                S.belumAdaRiwayatSaldo,
                style: const TextStyle(color: CenTheme.sub, fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            S.riwayatSaldoHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: CenTheme.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _activityCard({bool stretch = false}) {
    final entries = _store.entries;
    final shown = entries.take(6).toList();
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeader(
          S.aktivitas,
          action: entries.isEmpty
              ? null
              : _pillAction(S.lihatSemua, () => widget.onOpenTab?.call(3)),
        ),
        if (shown.isEmpty)
          // Empty state: teks ditengah, copy rata kanan-kiri agar rapi di card tinggi.
          Expanded(
            flex: stretch ? 1 : 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: stretch ? 320 : 208),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 12, 30, 34),
                  child: EmptyPanel(
                    center: true,
                    icon: Icons.receipt_long_outlined,
                    title: S.belumAdaAktivitas,
                  ),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: CenTheme.line,
                      indent: 26,
                      endIndent: 26,
                    ),
                  _activityRow(shown[i]),
                ],
              ],
            ),
          ),
        if (stretch && shown.isNotEmpty) const Spacer(),
      ],
    );
    return _card(child: stretch ? SizedBox.expand(child: content) : content);
  }

  Widget _activityRow(LedgerEntry entry) {
    final color = entry.incoming ? CenTheme.green : CenTheme.red;
    final counterparty = entry.counterparty;
    final kind = entry.incoming ? S.masuk : S.keluar;
    final title = counterparty == null
        ? kind
        : '$kind · ${shortAddress(counterparty)}';
    final trail = <String>[
      formatStamp(entry.time),
      if (entry.txid != null)
        '${entry.txid!.substring(0, entry.txid!.length < 8 ? entry.txid!.length : 8)}…',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(
              entry.incoming ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CenTheme.body(
                    13,
                    color: CenTheme.txt,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CenTheme.mono(9.5, color: CenTheme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatSignedCen(entry.amountPradha, incoming: entry.incoming),
            style: CenTheme.mono(
              13,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard() {
    final addresses = _store.addresses;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            S.alamatTersimpan,
            action: _pillAction(S.tambahAlamat, _addAddress, icon: Icons.add_rounded),
          ),
          if (addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
              child: EmptyPanel(
                icon: Icons.bookmark_border_rounded,
                title: S.alamatKosongJudul,
                body: S.alamatKosongBody,
                hint: S.alamatKosongHint,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  for (final address in addresses.take(4)) _addressRow(address),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _addressRow(SavedAddress address) {
    return InkWell(
      onTap: () => widget.onSend?.call(address.address),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
        child: Row(
          children: [
            // Fixed badge column: variable label widths would otherwise shift
            // the address text row to row.
            SizedBox(
              width: 74,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: CenTheme.acid.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 60),
                    child: Text(
                      address.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CenTheme.body(
                        9,
                        color: CenTheme.acid,
                        weight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                shortAddress(address.address),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CenTheme.mono(11.5, color: CenTheme.sub),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => widget.onSend?.call(address.address),
              tooltip: S.kirimKeAlamat,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              icon: const Icon(Icons.north_east_rounded, size: 14, color: CenTheme.acid),
            ),
            IconButton(
              onPressed: () => _removeAddress(address),
              tooltip: S.hapus,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 30),
              icon: const Icon(Icons.close_rounded, size: 14, color: CenTheme.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backupCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x1FE0B878), Color(0x08E0B878)],
        ),
        color: CenTheme.cardWarn,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CenTheme.warn.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: CenTheme.warn),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  S.cadangkanWallet,
                  style: CenTheme.body(
                    13,
                    color: CenTheme.txt,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            S.cadangkanBody,
            style: CenTheme.body(
              11.5,
              color: CenTheme.sub,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            child: OutlinedButton.icon(
              onPressed: () => widget.onOpenTab?.call(4),
              icon: const Icon(Icons.key_rounded, size: 13),
              label: Text(S.cadangkanSekarang),
              style: OutlinedButton.styleFrom(
                foregroundColor: CenTheme.warn,
                side: BorderSide(color: CenTheme.warn.withValues(alpha: 0.45)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagnosticsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(S.diagnostik),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
            child: Column(
              children: [
                _diagnosticRow(
                  S.status,
                  _nodeOffline ? S.terputus : S.sinkron,
                  color: _nodeOffline ? CenTheme.red : CenTheme.green,
                ),
                _diagnosticRow(S.jaringan, 'Mainnet · cen69'),
                _diagnosticRow(
                  S.estimasiFee,
                  _feePradha == null ? '—' : '${formatCen(_feePradha!)} CEN',
                ),
                _diagnosticRow(S.genesis, _genesisPrefix, mono: true, last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagnosticRow(
    String label,
    String value, {
    Color? color,
    bool mono = false,
    bool last = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: CenTheme.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: CenTheme.body(11.5, color: CenTheme.muted),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: mono
                ? CenTheme.mono(11, weight: FontWeight.w500, color: color ?? CenTheme.sub)
                : CenTheme.body(
                    11.5,
                    color: color ?? CenTheme.txt,
                    weight: FontWeight.w600,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _cardHeader(String title, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 18, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: CenTheme.display(14, weight: FontWeight.w600),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  /// Small acid pill used for in-card links such as "See all".
  Widget _pillAction(String label, VoidCallback onTap, {IconData? icon}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: CenTheme.acid,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: CenTheme.line),
        ),
        textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    Color? color,
    Color? borderColor,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? CenTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? CenTheme.line),
      ),
      child: child,
    );
  }

  Widget _primaryAction(String label, IconData icon, VoidCallback? onTap) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: CenTheme.acid,
        foregroundColor: CenTheme.bg,
        disabledBackgroundColor: CenTheme.line,
        disabledForegroundColor: CenTheme.muted,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(118, 40),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _secondaryAction(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: CenTheme.txt,
        backgroundColor: Colors.white.withValues(alpha: 0.02),
        side: const BorderSide(color: CenTheme.line),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(118, 40),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _addAddress() async {
    final draft = await showDialog<_AddressDraft>(
      context: context,
      builder: (_) => _AddressDialog(wallet: widget.wallet),
    );
    if (draft == null) return;
    _store.addAddress(
      label: draft.label.isEmpty ? shortAddress(draft.address) : draft.label,
      address: draft.address,
      now: DateTime.now(),
    );
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.alamatTersimpanPesan),
        behavior: SnackBarBehavior.floating,
        backgroundColor: CenTheme.bg1,
      ),
    );
  }

  Future<void> _removeAddress(SavedAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CenTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(S.hapusAlamatJudul, style: const TextStyle(fontSize: 15)),
        content: Text(
          S.hapusAlamatBody,
          style: const TextStyle(color: CenTheme.sub, fontSize: 12, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.batal, style: const TextStyle(color: CenTheme.sub)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(S.hapus, style: const TextStyle(color: CenTheme.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _store.removeAddress(address.id);
    await _save();
  }
}

class _AddressDraft {
  const _AddressDraft({required this.label, required this.address});

  final String label;
  final String address;
}

class _AddressDialog extends StatefulWidget {
  const _AddressDialog({required this.wallet});

  final CenWallet wallet;

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final TextEditingController _label = TextEditingController();
  final TextEditingController _address = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    final address = _address.text.trim();
    if (!isValidCenAddress(address, widget.wallet.network)) {
      setState(() => _error = S.alamatTidakValid);
      return;
    }
    Navigator.of(context).pop(
      _AddressDraft(label: _label.text.trim(), address: address.toLowerCase()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CenTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        S.alamatTersimpan,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(_label, S.labelAlamat, S.labelAlamatHint),
            const SizedBox(height: 12),
            _field(_address, 'CEN', 'cen69:…', mono: true),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: CenTheme.red, fontSize: 11, height: 1.4),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.batal, style: const TextStyle(color: CenTheme.sub)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(S.simpan, style: const TextStyle(color: CenTheme.acid)),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    bool mono = false,
  }) {
    return TextField(
      controller: controller,
      autofocus: label == S.labelAlamat,
      style: TextStyle(
        color: CenTheme.txt,
        fontSize: 12,
        fontFamily: mono ? 'monospace' : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: CenTheme.muted, fontSize: 11),
        labelStyle: const TextStyle(color: CenTheme.sub, fontSize: 11),
        filled: true,
        fillColor: CenTheme.bg1,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: CenTheme.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: CenTheme.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: CenTheme.acid),
        ),
      ),
    );
  }
}