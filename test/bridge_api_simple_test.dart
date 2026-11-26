import 'package:celenium_wallet/services/bridge_api_simple.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BridgeApi base URL normalization', () {
    test('strips trailing /api to avoid /api/api double path', () {
      final api = BridgeApi(baseUrl: 'https://celenium.web.id/api');
      expect(api.baseUrl, 'https://celenium.web.id');
    });

    test('strips trailing slash', () {
      final api = BridgeApi(baseUrl: 'https://celenium.web.id/');
      expect(api.baseUrl, 'https://celenium.web.id');
    });

    test('strips /api/ with trailing slash', () {
      final api = BridgeApi(baseUrl: 'https://celenium.web.id/api/');
      expect(api.baseUrl, 'https://celenium.web.id');
    });

    test('keeps plain host unchanged', () {
      final api = BridgeApi(baseUrl: 'https://celenium.web.id');
      expect(api.baseUrl, 'https://celenium.web.id');
    });
  });

  group('BridgeApi balance address encoding', () {
    // The bridge answers {"error":"balance query failed"} for a percent-encoded
    // prefix, so the colon has to survive into the query string.
    const address =
        'cen69:qraahfcp74y9n5njy0hvk5v0jcdyv3mw0ly5am4qfwj337wh7tqlxckwq6zrn';

    test('leaves the cen69: colon unescaped', () {
      final q = BridgeApi.encodeAddressForQuery(address);
      expect(q, address);
      expect(q.contains('%3A'), isFalse);
    });

    test('still escapes characters that would break the query', () {
      final q = BridgeApi.encodeAddressForQuery('cen69:a b&c');
      // encodeQueryComponent uses + for spaces (form-encoding), which is valid
      // in a query value; either + or %20 is acceptable, but the raw chars must
      // not leak through.
      expect(q.contains(' '), isFalse);
      expect(q.contains('&'), isFalse);
      expect(q.startsWith('cen69:'), isTrue);
    });
  });
}
