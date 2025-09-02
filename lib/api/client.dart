import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lightweight HTTP client for Neptune Spring Boot backend.
class ApiClient {
  final String baseUrl;
  final String? authToken;
  final http.Client _http;

  ApiClient({required this.baseUrl, this.authToken, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  Map<String, String> _headers() => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleaned = path.startsWith('/') ? path : '/$path';
    return Uri.parse(normalized + cleaned).replace(queryParameters: query);
  }

  /// Fetches balances for a given user.
  /// Expected endpoint: GET /api/users/{userId}/balances
  /// Accepts flexible response shapes and attempts to parse into a category->amount map.
  Future<Map<String, double>> fetchBalancesForUser(String userId, {Duration timeout = const Duration(seconds: 10)}) async {
    final url = _uri('/api/users/$userId/balances');
    final resp = await _http.get(url, headers: _headers()).timeout(timeout);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException('Failed to fetch balances (${resp.statusCode})');
    }
    final body = resp.body.isEmpty ? {} : json.decode(resp.body);
    return _parseBalances(body);
  }

  /// Robust parser for multiple common shapes.
  Map<String, double> _parseBalances(dynamic data) {
    final Map<String, double> out = {};

    void put(String key, num? value) {
      if (value == null) return;
      out[_normalizeLabel(key)] = value.toDouble();
    }

    if (data is Map) {
      // Case: { balances: { Savings: 123, Deposits: 456, ... } }
      if (data['balances'] is Map) {
        final m = Map.from(data['balances']);
        for (final e in m.entries) {
          final v = e.value;
          if (v is num) put(e.key.toString(), v);
        }
      }
      // Case: flat map { savings: 123, overdraft: -50, ... }
      for (final e in data.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is num) {
          put(k, v);
        }
      }
      // Case: { accounts: [ { type: 'SAVINGS', balance: 123 }, ... ] }
      if (data['accounts'] is List) {
        for (final it in (data['accounts'] as List)) {
          if (it is Map) {
            final type = (it['type'] ?? it['label'] ?? it['name'] ?? '').toString();
            final bal = it['balance'] ?? it['amount'] ?? it['value'];
            if (bal is num) put(type, bal);
          }
        }
      }
    } else if (data is List) {
      // Case: [ { label: 'Savings', amount: 123 } ]
      for (final it in data) {
        if (it is Map) {
          final label = (it['label'] ?? it['type'] ?? it['name'] ?? '').toString();
          final bal = it['amount'] ?? it['balance'] ?? it['value'];
          if (bal is num) put(label, bal);
        }
      }
    }

    // Ensure deterministic order is not required by callers; just return.
    return out;
  }

  String _normalizeLabel(String raw) {
    final s = raw.trim();
    // Map some common aliases to app labels
    final lower = s.toLowerCase();
    if (lower.contains('saving')) return 'Savings';
    if (lower.contains('overdraft') || lower == 'od') return 'Overdraft';
    if (lower.contains('deposit')) return 'Deposits';
    if (lower.contains('loan')) return 'Loans';
    return s[0].toUpperCase() + s.substring(1);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

