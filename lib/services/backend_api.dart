import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/remedy_data.dart';

class BackendApi {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: String.fromEnvironment(
      'DIVINEWALL_API_URL',
      defaultValue: 'https://admin.kubervastu.com/public',
    ),
  );

  bool get enabled => baseUrl.trim().isNotEmpty;

  Future<Map<String, dynamic>?> register({
    required String name,
    required String gender,
    required String email,
    required String phone,
    required String place,
    required String userType,
    required String username,
    required String password,
  }) async {
    if (!enabled) return null;
    return _request(
      'POST',
      '/api/auth/register',
      {
        'name': name,
        'gender': gender,
        'email': email,
        'phone': phone,
        'place': place,
        'userType': userType,
        'username': username,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    if (!enabled) return null;
    return _request(
      'POST',
      '/api/auth/login',
      {
        'username': username,
        'password': password,
      },
    );
  }

  Future<void> deleteAccount(String token, String password) async {
    if (!enabled) throw Exception('Account service is unavailable');
    await _request('DELETE', '/api/me', {'password': password}, token);
  }

  Future<void> logout(String token) async {
    if (!enabled || token.trim().isEmpty) return;
    await _request(
      'POST',
      '/api/auth/logout',
      null,
      token,
    );
  }

  Future<Map<String, dynamic>?> fetchMe(String token) async {
    if (!enabled || token.trim().isEmpty) return null;
    return _get('/api/me', token: token);
  }

  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
    String gender = '',
    String place = '',
    String userType = '',
    String username = '',
  }) async {
    if (!enabled) return;
    await _request(
      'POST',
      '/api/users',
      {
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'place': place,
        'userType': userType,
        'username': username,
      },
    );
  }

  Future<Map<String, dynamic>?> saveOrder({
    required String email,
    required String remedyId,
    String? token,
  }) async {
    if (!enabled) return null;
    return _request(
      'POST',
      '/api/orders',
      {
        'email': email,
        'remedyId': remedyId,
      },
      token,
    );
  }

  Future<Map<String, dynamic>?> checkoutCart({
    required String email,
    required List<Map<String, dynamic>> items,
    required String token,
  }) async {
    if (!enabled) return null;
    return _request(
      'POST',
      '/api/orders/checkout',
      {'email': email, 'items': items},
      token,
    );
  }

  Future<Map<String, dynamic>?> createPayment({
    required List<Map<String, dynamic>> items,
    required String token,
    required Map<String, String> shipping,
    String? returnUrl,
  }) async {
    if (!enabled) return null;
    return _request(
      'POST',
      '/api/payments/create',
      {
        'items': items,
        'shipping': shipping,
        if (returnUrl != null && returnUrl.isNotEmpty) 'returnUrl': returnUrl,
      },
      token,
    );
  }

  Future<Map<String, dynamic>?> fetchPaymentStatus({
    required String purchaseId,
    required String token,
  }) async {
    if (!enabled) return null;
    return _get(
      '/api/payments/${Uri.encodeComponent(purchaseId)}/status',
      token: token,
    );
  }

  Future<List<RemedyItem>> fetchRemedies() async {
    if (!enabled) return RemedyCatalog.load();
    try {
      final data = await _get('/api/remedies');
      final rows = data['remedies'] as List<dynamic>? ?? const [];
      if (rows.isEmpty) return RemedyCatalog.load();
      return rows
          .map((item) => RemedyItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return RemedyCatalog.load();
    }
  }

  Future<Map<String, dynamic>> fetchAdminOverview() async {
    if (!enabled) {
      throw Exception('Backend URL is not configured');
    }
    return _get('/api/admin/overview');
  }

  Future<Map<String, dynamic>?> fetchAppUpdate() async {
    if (!enabled) return null;
    return _get('/api/app-update');
  }

  Future<void> saveAdminRemedy(RemedyItem remedy) async {
    if (!enabled) return;
    final path = remedy.id.trim().isEmpty
        ? '/api/admin/remedies'
        : '/api/admin/remedies/${Uri.encodeComponent(remedy.id)}';
    await _request(
      remedy.id.trim().isEmpty ? 'POST' : 'PUT',
      path,
      remedy.toJson(),
    );
  }

  Future<void> deleteAdminRemedy(String id) async {
    if (!enabled) return;
    await _request('DELETE', '/api/admin/remedies/${Uri.encodeComponent(id)}');
  }

  Future<Map<String, dynamic>> _get(String path, {String? token}) async {
    final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');
    final headers = {
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };
    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException.fromResponse(response);
    }
    return response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
    String? token,
  ]) async {
    final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };
    final encodedBody = body == null ? null : jsonEncode(body);
    final response = await switch (method) {
      'POST' => http.post(uri, headers: headers, body: encodedBody),
      'PUT' => http.put(uri, headers: headers, body: encodedBody),
      'DELETE' => http.delete(uri, headers: headers, body: encodedBody),
      _ => http.post(uri, headers: headers, body: encodedBody),
    }
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException.fromResponse(response);
    }
    return response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
  }
}

class BackendApiException implements Exception {
  final String message;
  final int statusCode;

  const BackendApiException(this.message, this.statusCode);

  factory BackendApiException.fromResponse(http.Response response) {
    var message = 'Server request failed';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['error'] as String? ?? message;
    } catch (_) {
      if (response.body.trim().isNotEmpty) message = response.body.trim();
    }
    return BackendApiException(message, response.statusCode);
  }

  @override
  String toString() => message;
}
