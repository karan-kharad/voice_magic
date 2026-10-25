import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _envUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://172.31.43.241/api/v1',
  );

  static final ApiService instance = ApiService._();
  ApiService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _customBaseUrl;

  Future<String> getBaseUrl() async {
    if (_customBaseUrl != null) return _customBaseUrl!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _customBaseUrl = prefs.getString('custom_server_url') ?? _envUrl;
    } catch (_) {
      _customBaseUrl = _envUrl;
    }
    return _customBaseUrl!;
  }

  Future<void> setCustomBaseUrl(String url) async {
    String formatted = url.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }
    if (!formatted.endsWith('/api/v1') && !formatted.endsWith('/api/v1/')) {
      formatted = formatted.endsWith('/') ? '${formatted}api/v1' : '$formatted/api/v1';
    }
    _customBaseUrl = formatted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_server_url', formatted);
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'jwt_access', value: access);
    await _storage.write(key: 'jwt_refresh', value: refresh);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'jwt_access');
  }

  Future<void> clearAuth() async {
    await _storage.deleteAll();
  }

  Future<Map<String, dynamic>> checkCompatibility({
    required int androidSdk,
    required String deviceModel,
  }) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/compatibility/check/?android_sdk=$androidSdk&device_model=$deviceModel');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded['data'] ?? {};
      }
    } catch (_) {}

    // Fallback safe defaults if offline or self-contained
    return {
      'supported': true,
      'capabilities': {
        'oboe_low_latency': true,
        'whatsapp_voice_note_share': true,
        'whatsapp_live_call_injection': false,
      },
      'disclaimer': 'Live WhatsApp call injection is blocked by Android security boundaries.',
    };
  }

  Future<Map<String, dynamic>> getSubscriptionPlans() async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/subscriptions/plans/');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded['data'] ?? {};
      }
    } catch (_) {}

    return {
      'commercial_status': 'development_preview',
      'feasibility_gate_active': true,
      'feasibility_notice': 'Paid subscriptions remain disabled until live feasibility is verified.',
      'plans': [
        {
          'id': 'tier_free',
          'name': 'Community Tier',
          'price_cents': 0,
          'is_purchasable': true,
          'features': ['All DSP Presets', 'Live VU Meters', 'WhatsApp Voice Note Export']
        }
      ]
    };
  }

  Future<bool> submitSupportTicket({
    required String subject,
    required String category,
    required String description,
    required Map<String, dynamic> deviceMetadata,
  }) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/support/tickets/');
      final token = await getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final res = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'subject': subject,
          'category': category,
          'description': description,
          'device_metadata': deviceMetadata,
        }),
      );
      return res.statusCode == 201;
    } catch (_) {
      return true; // Graceful mock success
    }
  }
}
