import 'package:flutter/material.dart';

import '../format.dart';
import '../services/bridge_api_simple.dart';
import '../services/cen_wallet.dart';
import '../services/wallet_data.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/empty_panel.dart';

/// Full ledger view. Rows are the same records the dashboard reads from
/// `WalletData`; the filter only narrows what is already on disk.
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key, required this.wallet, required this.api});

  final CenWallet wallet;
  final BridgeApi api;

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  int _balance = -1;
  WalletData? _data;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await WalletDataStore.load(widget.wallet.address);
    if (!mounted) return;
    setState(() => _data = data);
    try {
      final balance = await widget.api.fetchBalance(widget.wallet.address);
      if (!mounted) return;
      setState(() => _balance = balance);
    } catch (_) {
      if (!mounted) return;
      setState(() => _balance = -1);
    }
  }

  List<LedgerEntry> get _rows {
    final all = _data?.entries ?? const <LedgerEntry>[];
    switch (_filter) {
      case _Filter.incoming:
        return all.where((e) => e.incoming).toList();
      case _Filter.outgoing:
        return all.where((e) => !e.incoming).toList();
      case _Filter.all:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 26 : 16, wide ? 24 : 18, wide ? 26 : 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    S.riwayat,
                    style: const TextStyle(
                      color: CenTheme.txt,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  _FilterChips(
                    value: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                decoration: BoxDecoration(
                  color: CenTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CenTheme.line),
                ),
                child: rows.isEmpty
                    ? EmptyPanel(
                        icon: Icons.receipt_long_outlined,
                        title: S.belumAdaAktivitas,
                        body: S.aktivitasKosongBody,
                        hint: S.aktivitasKosongHint,
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            if (i > 0) const Divider(height: 1, color: CenTheme.line),
                            _Row(entry: rows[i]),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: CenTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CenTheme.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.alamatTerpantau,
                      style: const TextStyle(
                        color: CenTheme.muted,
                        fontSize: 9.5,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      widget.wallet.address,
                      style: const TextStyle(
                        color: CenTheme.sub,
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _balance < 0
                          ? S.memuat
                          : '${S.saldoTersedia}: ${formatCen(_balance)} CEN',
                      style: TextStyle(
                        color: _balance < 0 ? CenTheme.muted : CenTheme.green,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _Filter { all, incoming, outgoing }

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.onChanged});

  final _Filter value;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <_Filter, String>{
      _Filter.all: S.semua,
      _Filter.incoming: S.masuk,
      _Filter.outgoing: S.keluar,
    };
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: CenTheme.bg1,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: CenTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in items.entries)
            GestureDetector(
              onTap: () => onChanged(entry.key),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: value == entry.key
                      ? CenTheme.acid.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: value == entry.key ? CenTheme.acid : CenTheme.sub,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.incoming ? CenTheme.green : CenTheme.red;
    final counterparty = entry.counterparty;
    final counterpartyLabel =
        counterparty == null ? S.mainnetAlamatAktif : shortAddress(counterparty);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(
              entry.incoming ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 15,
              color: color,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.incoming ? S.masuk : S.keluar} · $counterpartyLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CenTheme.txt,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatStamp(entry.time),
                  style: const TextStyle(color: CenTheme.muted, fontSize: 9.5),
                ),
                if (entry.txid != null) ...[
                  const SizedBox(height: 2),
                  SelectableText(
                    entry.txid!,
                    maxLines: 1,
                    style: const TextStyle(
                      color: CenTheme.muted,
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatSignedCen(entry.amountPradha, incoming: entry.incoming),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}