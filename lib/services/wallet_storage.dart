import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Key/value storage backed by the OS keychain.
///
/// Every call is guarded: on a desktop without a keyring daemon (WSL, minimal
/// Linux installs, headless sessions) secure storage throws `PlatformException`.
/// The wallet must still open in that state, so reads fall back to null and
/// writes are dropped with a single warning.
class WalletStorage {
  static const _kMnemonic = 'wallet_mnemonic';
  static const _kPinHash = 'wallet_pin_hash';
  static const _kBiometricEnabled = 'wallet_biometric';
  static const _kLanguage = 'wallet_language';

  // Multi-wallet index. A user may hold several CEN wallets and switch between
  // them by recovery phrase, so mnemonics are stored per id and the index keeps
  // the public address only. The active pointer is what "logged in" means; it is
  // cleared on logout while the wallets themselves stay on the device.
  static const _kWallets = 'wallet_list';
  static const _kActive = 'wallet_active';
  static const _kMnemonicPrefix = 'wallet_mnemonic_';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static bool _warned = false;

  static void _warnOnce(Object e) {
    if (_warned) return;
    _warned = true;
    debugPrint('WalletStorage: keychain unavailable, continuing in memory only ($e)');
  }

  static Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      _warnOnce(e);
      return null;
    }
  }

  static Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      _warnOnce(e);
    }
  }

  static Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      _warnOnce(e);
    }
  }

  static Future<void> saveWallet(String mnemonic) => _write(_kMnemonic, mnemonic);

  static Future<String?> loadMnemonic() async {
    final active = await activeWalletId();
    if (active != null) {
      final m = await mnemonicFor(active);
      if (m != null) return m;
    }
    return _read(_kMnemonic);
  }

  static Future<void> clearWallet() async {
    final active = await activeWalletId();
    if (active != null) {
      final wallets = await listWallets();
      wallets.removeWhere((w) => w.id == active);
      await _writeWallets(wallets);
      await _delete('$_kMnemonicPrefix$active');
      await _delete(_kActive);
    }
    await _delete(_kMnemonic);
  }

  static Future<bool> hasWallet() async {
    final active = await activeWalletId();
    if (active != null) {
      final m = await mnemonicFor(active);
      if (m != null && m.isNotEmpty) return true;
    }
    final legacy = await _read(_kMnemonic);
    return legacy != null && legacy.isNotEmpty;
  }

  /// True when at least one wallet is known, even if none is currently open
  /// (that is the state right after logging out).
  static Future<bool> hasAnyWallet() async {
    if ((await listWallets()).isNotEmpty) return true;
    return hasWallet();
  }

  // --- wallet index -------------------------------------------------------

  static Future<List<StoredWallet>> listWallets() async {
    final raw = await _read(_kWallets);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((m) => StoredWallet.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('WalletStorage: wallet index unreadable ($e)');
      return [];
    }
  }

  static Future<void> _writeWallets(List<StoredWallet> wallets) =>
      _write(_kWallets, jsonEncode(wallets.map((w) => w.toJson()).toList()));

  static Future<String?> activeWalletId() async {
    final v = await _read(_kActive);
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> setActiveWallet(String? id) async {
    if (id == null || id.isEmpty) {
      await _delete(_kActive);
    } else {
      await _write(_kActive, id);
    }
  }

  /// Logout: forget which wallet is open but keep every saved wallet (and its
  /// mnemonic) so the user can pick it again from the login screen.
  static Future<void> forgetActiveWallet() async {
    await _delete(_kActive);
    // The legacy mirror predates the index and would otherwise auto-unlock.
    await _delete(_kMnemonic);
  }

  static Future<String?> mnemonicFor(String id) async {
    final v = await _read('$_kMnemonicPrefix$id');
    if (v != null && v.isNotEmpty) return v;
    // Builds before the multi-wallet index kept a single mnemonic under one key.
    final legacy = await _read(_kMnemonic);
    if (legacy == null || legacy.isEmpty) return null;
    final wallets = await listWallets();
    return wallets.length == 1 && wallets.first.id == id ? legacy : null;
  }

  /// Adds or refreshes a wallet, then makes it the active one.
  static Future<StoredWallet> registerWallet(
    String mnemonic, {
    required String address,
    String? label,
  }) async {
    final wallets = await listWallets();
    var index = wallets.indexWhere((w) => w.address == address);
    if (index < 0) index = wallets.indexWhere((w) => w.address.isEmpty);
    final existing = index >= 0 ? wallets[index] : null;
    final id = existing?.id ??
        'w${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    final entry = StoredWallet(
      id: id,
      address: address,
      label: label ?? existing?.label ?? 'Wallet ${wallets.length + 1}',
      createdAt: existing?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );
    if (index >= 0) {
      wallets[index] = entry;
    } else {
      wallets.add(entry);
    }
    await _write('$_kMnemonicPrefix$id', mnemonic);
    await _writeWallets(wallets);
    await _write(_kMnemonic, mnemonic); // mirror for pre-index builds
    await setActiveWallet(id);
    return entry;
  }

  /// One-time upgrade from the single-wallet layout.
  static Future<void> migrateLegacyWallet(String address) async {
    final wallets = await listWallets();
    if (wallets.isNotEmpty) return;
    final legacy = await _read(_kMnemonic);
    if (legacy == null || legacy.isEmpty) return;
    await registerWallet(legacy, address: address, label: 'Wallet 1');
  }

  /// PBKDF2-HMAC-SHA256, 120k iterations, 16-byte random salt.
  /// A 4-6 digit PIN has 10^4-10^6 candidates; a fast hash would fall in
  /// milliseconds, so the stored value is deliberately slow to verify.
  static const int _pinIterations = 120000;
  static const int _pinLength = 32;

  static Future<void> savePin(String pin) async {
    final salt = _randomBytes(16);
    final dk = _pbkdf2(utf8.encode(pin), salt, _pinIterations, _pinLength);
    await _write(
      _kPinHash,
      'pbkdf2\$$_pinIterations\$${base64Encode(salt)}\$${base64Encode(dk)}',
    );
  }

  static Future<bool> verifyPin(String pin) async {
    final stored = await _read(_kPinHash);
    if (stored == null || stored.isEmpty) return false;

    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2') {
      // Legacy unsalted digest: compare, then accept it only once.
      return stored == _legacyHash(pin);
    }

    final iterations = int.tryParse(parts[1]) ?? _pinIterations;
    final salt = base64Decode(parts[2]);
    final expected = base64Decode(parts[3]);
    final actual = _pbkdf2(utf8.encode(pin), salt, iterations, expected.length);
    return _constantTimeEquals(expected, actual);
  }

  static Future<void> clearPin() => _delete(_kPinHash);

  static Future<bool> hasPin() async {
    final v = await _read(_kPinHash);
    return v != null && v.isNotEmpty;
  }

  static Future<void> saveBiometric(bool enabled) =>
      _write(_kBiometricEnabled, enabled ? '1' : '0');

  static Future<bool> loadBiometric() async => (await _read(_kBiometricEnabled)) == '1';

  /// Language chosen during onboarding. Null means the user has not picked
  /// one yet, so the picker must be shown before any wallet work starts.
  static Future<String?> loadLocale() => _read(_kLanguage);

  static Future<void> saveLocale(String locale) => _write(_kLanguage, locale);

  static Uint8List _randomBytes(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => r.nextInt(256)));
  }

  static Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations, int length) {
    final hmac = Hmac(sha256, password);
    final blocks = (length / 32).ceil();
    final out = BytesBuilder();
    for (var block = 1; block <= blocks; block++) {
      final first = Uint8List.fromList([
        ...salt,
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ]);
      var u = Uint8List.fromList(hmac.convert(first).bytes);
      final acc = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < acc.length; j++) {
          acc[j] ^= u[j];
        }
      }
      out.add(acc);
    }
    return Uint8List.sublistView(out.toBytes(), 0, length);
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static String _legacyHash(String input) => sha256.convert(utf8.encode(input)).toString();

  // Compatibility aliases
  static Future<String?> getMnemonic() => loadMnemonic();
  static Future<bool> isBiometricEnabled() => loadBiometric();
  static Future<void> setBiometricEnabled(bool v) => saveBiometric(v);
  static Future<void> setPin(String pin) => savePin(pin);
  static Future<void> clear() async {
    await clearWallet();
    await clearPin();
  }
}

/// Public metadata for one saved wallet. The mnemonic stays in the keychain
/// under `wallet_mnemonic_<id>`; this object never holds key material.
class StoredWallet {
  final String id;
  final String address;
  final String label;
  final int createdAt;

  const StoredWallet({
    required this.id,
    required this.address,
    required this.label,
    required this.createdAt,
  });

  factory StoredWallet.fromJson(Map<String, dynamic> json) => StoredWallet(
        id: (json['id'] ?? '') as String,
        address: (json['address'] ?? '') as String,
        label: (json['label'] ?? 'Wallet') as String,
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'address': address,
        'label': label,
        'createdAt': createdAt,
      };

  String get shortAddress =>
      address.length <= 18 ? address : '${address.substring(0, 9)}…${address.substring(address.length - 6)}';
}
