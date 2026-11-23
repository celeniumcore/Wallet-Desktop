import 'dart:convert';
import 'package:http/http.dart' as http;

class BridgeApi {
  BridgeApi({required this.baseUrl});
  final String baseUrl;

  /// Endpoints below are written as `/api/...`, so a base URL that already ends
  /// in `/api` must be trimmed; otherwise every call becomes `/api/api/...` and
  /// 404s, which used to surface as a permanent "node offline" banner.
  String get _root =>
      baseUrl.endsWith('/api') ? baseUrl.substring(0, baseUrl.length - 4) : baseUrl;

  static const Duration timeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 25);

  Future<int> fetchBalance(String address) async {
    final body = await _get('/api/balance?address=' + address);
    if (body is Map<String, dynamic>) {
      final b = body['balancePradha'];
      if (b is num) return b.toInt();
    }
    throw Exception('balance not found');
  }

  Future<int> fetchFee() async {
    final body = await _get('/api/fee');
    if (body is Map<String, dynamic>) {
      final f = body['feePradha'];
      if (f is num) return f.toInt();
    }
    throw Exception('fee not available');
  }

  Future<String> sendCoins({
    required String from,
    required String to,
    required int amountPradha,
    required int feePradha,
    required String privateKeyHex,
  }) async {
    final body = await _post('/api/send', <String, dynamic>{
      'from': from,
      'to': to,
      'amountPradha': amountPradha,
      'feePradha': feePradha,
      'privateKeyHex': privateKeyHex,
    });
    if (body is Map<String, dynamic>) {
      final txid = body['txid'];
      if (txid is String) return txid;
      final err = body['error'];
      throw Exception(err ?? 'send failed');
    }
    throw Exception('unexpected send response');
  }

  Future<Map<String, dynamic>?> fetchStatus() async {
    try {
      final r = await _get('/api/status');
      if (r is Map<String, dynamic>) return r;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Object?> _get(String path) async {
    final uri = Uri.parse(_root + path);
    final response = await http.get(uri).timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ' + response.statusCode.toString());
    }
    return jsonDecode(response.body);
  }

  Future<Object?> _post(String path, Map<String, dynamic> payload) async {
    final uri = Uri.parse(_root + path);
    final response = await http.post(
      uri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(sendTimeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ' + response.statusCode.toString());
    }
    return jsonDecode(response.body);
  }
}
