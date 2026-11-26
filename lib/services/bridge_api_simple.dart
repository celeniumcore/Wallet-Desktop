import 'dart:convert';
import 'package:http/http.dart' as http;

class BridgeApi {
  BridgeApi({required String baseUrl}) : baseUrl = _normalizeBase(baseUrl);
  final String baseUrl;

  /// Endpoints below are written as `/api/...`. Normalize the base URL so a
  /// value that already ends with `/api` or has a trailing slash does not
  /// produce `/api/api/...` and 404, which used to surface as a permanent
  /// "node offline" banner.
  static String _normalizeBase(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.endsWith('/api')) {
      u = u.substring(0, u.length - 4);
    }
    return u;
  }

  static const Duration timeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 25);

  /// The bridge reads the address verbatim out of the query string. A
  /// percent-encoded prefix (`cen69%3A...`) comes back as
  /// `{"error":"balance query failed"}` with no `balancePradha`, which the
  /// wallet then reports as a dead node. A colon is legal in a query
  /// (RFC 3986 pchar), so restore it after escaping the rest of the value.
  static String encodeAddressForQuery(String address) =>
      Uri.encodeQueryComponent(address).replaceAll('%3A', ':');

  Future<int> fetchBalance(String address) async {
    final body = await _get(
      '/api/balance?address=${encodeAddressForQuery(address)}',
    );
    if (body is Map<String, dynamic>) {
      final b = body['balancePradha'];
      if (b is num) return b.toInt();
      final err = body['error'];
      if (err is String) throw Exception('balance: $err');
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
    final uri = Uri.parse(baseUrl + path);
    final response = await http.get(uri).timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ' + response.statusCode.toString());
    }
    return jsonDecode(response.body);
  }

  Future<Object?> _post(String path, Map<String, dynamic> payload) async {
    final uri = Uri.parse(baseUrl + path);
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
