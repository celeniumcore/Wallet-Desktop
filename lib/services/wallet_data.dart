import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// One activity row.
///
/// The bridge exposes no per-address index, so every row here is derived from
/// something the device actually saw: a balance delta read back from the node,
/// or a send this wallet broadcast. Nothing is seeded.
@immutable
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.incoming,
    required this.amountPradha,
    required this.time,
    this.counterparty,
    this.txid,
  });

  final String id;
  final bool incoming;
  final int amountPradha;
  final DateTime time;
  final String? counterparty;
  final String? txid;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'in': incoming,
        'amt': amountPradha,
        't': time.millisecondsSinceEpoch,
        'cp': counterparty,
        'tx': txid,
      };

  static LedgerEntry? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final amt = raw['amt'];
    final at = raw['t'];
    if (id is! String || amt is! num || at is! num) return null;
    return LedgerEntry(
      id: id,
      incoming: raw['in'] == true,
      amountPradha: amt.toInt(),
      time: DateTime.fromMillisecondsSinceEpoch(at.toInt()),
      counterparty: raw['cp'] is String ? raw['cp'] as String : null,
      txid: raw['tx'] is String ? raw['tx'] as String : null,
    );
  }
}

/// A balance reading kept for the chart. Samples are throttled so a 15 second
/// poll does not turn into thousands of points.
@immutable
class BalanceSample {
  const BalanceSample({required this.time, required this.pradha});

  final DateTime time;
  final int pradha;

  Map<String, Object?> toJson() => <String, Object?>{
        't': time.millisecondsSinceEpoch,
        'p': pradha,
      };

  static BalanceSample? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final at = raw['t'];
    final pradha = raw['p'];
    if (at is! num || pradha is! num) return null;
    return BalanceSample(
      time: DateTime.fromMillisecondsSinceEpoch(at.toInt()),
      pradha: pradha.toInt(),
    );
  }
}

/// An address the user chose to keep. Rows are user data, never demo data.
@immutable
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.createdAt,
  });

  final String id;
  final String label;
  final String address;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'label': label,
        'addr': address,
        't': createdAt.millisecondsSinceEpoch,
      };

  static SavedAddress? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final label = raw['label'];
    final addr = raw['addr'];
    final at = raw['t'];
    if (id is! String || label is! String || addr is! String || at is! num) {
      return null;
    }
    return SavedAddress(
      id: id,
      label: label,
      address: addr,
      createdAt: DateTime.fromMillisecondsSinceEpoch(at.toInt()),
    );
  }
}

/// A send that was broadcast but whose balance change has not been observed
/// yet. It keeps the resulting drop from being logged twice.
class PendingSend {
  PendingSend({required this.totalPradha, required this.feePradha, required this.at});

  final int totalPradha;
  final int feePradha;
  final DateTime at;

  Map<String, Object?> toJson() => <String, Object?>{
        'total': totalPradha,
        'fee': feePradha,
        't': at.millisecondsSinceEpoch,
      };

  static PendingSend? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final total = raw['total'];
    final fee = raw['fee'];
    final at = raw['t'];
    if (total is! num || fee is! num || at is! num) return null;
    return PendingSend(
      totalPradha: total.toInt(),
      feePradha: fee.toInt(),
      at: DateTime.fromMillisecondsSinceEpoch(at.toInt()),
    );
  }
}

/// Everything the wallet page renders, persisted per address.
class WalletData {
  WalletData({
    this.lastBalance,
    List<LedgerEntry>? entries,
    List<BalanceSample>? samples,
    List<SavedAddress>? addresses,
    List<PendingSend>? pending,
    this.backupDismissed = false,
  })  : entries = entries ?? <LedgerEntry>[],
        samples = samples ?? <BalanceSample>[],
        addresses = addresses ?? <SavedAddress>[],
        pending = pending ?? <PendingSend>[];

  static const int maxEntries = 200;
  static const int maxSamples = 720;
  static const Duration _sampleGap = Duration(minutes: 10);
  static const Duration _pendingTtl = Duration(minutes: 45);

  int? lastBalance;
  final List<LedgerEntry> entries;
  final List<BalanceSample> samples;
  final List<SavedAddress> addresses;
  final List<PendingSend> pending;
  bool backupDismissed;

  bool get hasChart => samples.length >= 2;

  List<BalanceSample> samplesWithin(Duration window, DateTime now) {
    final from = now.subtract(window);
    return samples.where((s) => s.time.isAfter(from)).toList();
  }

  /// Folds a fresh balance reading into the ledger. Returns true when anything
  /// changed and therefore needs a write.
  bool observeBalance(int pradha, DateTime now) {
    var changed = false;
    final previous = lastBalance;
    lastBalance = pradha;

    if (previous != null && previous != pradha) {
      final delta = pradha - previous;
      if (delta > 0) {
        _push(LedgerEntry(
          id: 'obs-${now.millisecondsSinceEpoch}-in',
          incoming: true,
          amountPradha: delta,
          time: now,
        ));
        changed = true;
      } else if (!_consumePending(-delta, now)) {
        _push(LedgerEntry(
          id: 'obs-${now.millisecondsSinceEpoch}-out',
          incoming: false,
          amountPradha: -delta,
          time: now,
        ));
        changed = true;
      }
    }

    if (_shouldSample(pradha, now)) {
      samples.add(BalanceSample(time: now, pradha: pradha));
      changed = true;
    }

    pending.removeWhere((p) => now.difference(p.at) > _pendingTtl);
    _prune(now);
    return changed;
  }

  /// Records a send the moment the bridge returns a txid, so the row exists
  /// before the next balance poll.
  bool recordSend({
    required String to,
    required int amountPradha,
    required int feePradha,
    required String txid,
    required DateTime now,
  }) {
    if (entries.any((e) => e.txid == txid)) return false;
    _push(LedgerEntry(
      id: 'tx-$txid',
      incoming: false,
      amountPradha: amountPradha,
      time: now,
      counterparty: to,
      txid: txid,
    ));
    pending.add(PendingSend(
      totalPradha: amountPradha + feePradha,
      feePradha: feePradha,
      at: now,
    ));
    _prune(now);
    return true;
  }

  SavedAddress addAddress({required String label, required String address, required DateTime now}) {
    final entry = SavedAddress(
      id: 'addr-${now.microsecondsSinceEpoch}',
      label: label,
      address: address,
      createdAt: now,
    );
    addresses.removeWhere((a) => a.address == address);
    addresses.insert(0, entry);
    return entry;
  }

  bool removeAddress(String id) {
    final before = addresses.length;
    addresses.removeWhere((a) => a.id == id);
    return addresses.length != before;
  }

  bool get hasAddress => addresses.isNotEmpty;

  void _push(LedgerEntry entry) {
    if (entries.isNotEmpty) {
      final head = entries.first;
      final duplicate = head.incoming == entry.incoming &&
          head.amountPradha == entry.amountPradha &&
          entry.time.difference(head.time).inSeconds.abs() <= 3;
      if (duplicate) return;
    }
    entries.insert(0, entry);
    if (entries.length > maxEntries) entries.removeRange(maxEntries, entries.length);
  }

  bool _consumePending(int spent, DateTime now) {
    for (final p in pending) {
      if (now.difference(p.at) > _pendingTtl) continue;
      if ((spent - p.totalPradha).abs() <= p.feePradha + 1) {
        pending.remove(p);
        return true;
      }
    }
    return false;
  }

  bool _shouldSample(int pradha, DateTime now) {
    if (samples.isEmpty) return true;
    final last = samples.last;
    if (now.difference(last.time) >= _sampleGap) return true;
    return last.pradha != pradha && now.difference(last.time).inMinutes >= 2;
  }

  void _prune(DateTime now) {
    samples.removeWhere((s) => now.difference(s.time).inDays > 120);
    if (samples.length > maxSamples) {
      samples.removeRange(0, samples.length - maxSamples);
    }
    entries.sort((a, b) => b.time.compareTo(a.time));
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'v': 1,
        'balance': lastBalance,
        'entries': entries.map((e) => e.toJson()).toList(),
        'samples': samples.map((s) => s.toJson()).toList(),
        'addresses': addresses.map((a) => a.toJson()).toList(),
        'pending': pending.map((p) => p.toJson()).toList(),
        'backupDismissed': backupDismissed,
      };

  static WalletData fromJson(Object? raw) {
    if (raw is! Map) return WalletData();
    final entries = <LedgerEntry>[];
    for (final item in (raw['entries'] as List<Object?>? ?? const <Object?>[])) {
      final parsed = LedgerEntry.tryParse(item);
      if (parsed != null) entries.add(parsed);
    }
    final samples = <BalanceSample>[];
    for (final item in (raw['samples'] as List<Object?>? ?? const <Object?>[])) {
      final parsed = BalanceSample.tryParse(item);
      if (parsed != null) samples.add(parsed);
    }
    final addresses = <SavedAddress>[];
    for (final item in (raw['addresses'] as List<Object?>? ?? const <Object?>[])) {
      final parsed = SavedAddress.tryParse(item);
      if (parsed != null) addresses.add(parsed);
    }
    final pending = <PendingSend>[];
    for (final item in (raw['pending'] as List<Object?>? ?? const <Object?>[])) {
      final parsed = PendingSend.tryParse(item);
      if (parsed != null) pending.add(parsed);
    }
    final balance = raw['balance'];
    return WalletData(
      lastBalance: balance is num ? balance.toInt() : null,
      entries: entries,
      samples: samples,
      addresses: addresses,
      pending: pending,
      backupDismissed: raw['backupDismissed'] == true,
    );
  }
}

/// File-backed store, one JSON document per address. Address books and ledger
/// rows are user data and stay on the device.
class WalletDataStore {
  WalletDataStore._();

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static final Map<String, WalletData> _memo = <String, WalletData>{};

  static Future<WalletData> load(String address) async {
    final cached = _memo[address];
    if (cached != null) return cached;
    final file = await _file(address);
    var data = WalletData();
    if (await file.exists()) {
      try {
        data = WalletData.fromJson(jsonDecode(await file.readAsString()));
      } catch (_) {
        data = WalletData();
      }
    }
    _memo[address] = data;
    return data;
  }

  static Future<void> save(String address, WalletData data) async {
    _memo[address] = data;
    final file = await _file(address);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);
    await tmp.rename(file.path);
    revision.value++;
  }

  /// Forgets the parsed copy so the next load reads the file again.
  static Future<WalletData> reload(String address) async {
    _memo.remove(address);
    return load(address);
  }

  @visibleForTesting
  static void resetCache() => _memo.clear();

  static Future<File> _file(String address) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/wallet_data');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final safe = address.replaceAll(RegExp('[^A-Za-z0-9]'), '_');
    return File('${dir.path}/$safe.json');
  }
}