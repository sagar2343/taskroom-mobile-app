import 'dart:convert';
import 'package:http/http.dart';
import '../../../config/constant/http_constants.dart';
import '../../../config/routes/api_routes.dart';
import '../../../core/http_client/http_client.dart';
import '../model/analytics_model.dart';

class AnalyticsDataSource {
  final Client _client = kHttpClient;
  final String baseUrl = HttpConstants.getBaseURL;

  // ── GET /api/analytics/overview ──────────────────────────────────────
  Future<AnalyticsOverview> getOverview(String token) async {
    final res = await _client.get(
      Uri.parse('$baseUrl$APIRouteAnalyticsOverview'),
      headers: HttpConstants.getHttpHeaders(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return AnalyticsOverview.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to load overview');
  }

  // ── GET /api/analytics/productivity ──────────────────────────────────
  Future<ProductivityData> getProductivity(String token, {String? from, String? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final uri = Uri.parse('$baseUrl$APIRouteAnalyticsProductivity')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await _client.get(uri, headers: HttpConstants.getHttpHeaders(token));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return ProductivityData.fromJson(body['data']);
    }
    if (res.statusCode == 403) {
      throw PlanUpgradeRequired(
        message: body['message'] ?? 'Productivity scores require Pro plan.',
        neededPlan: body['neededPlan'] ?? 'pro',
      );
    }
    throw Exception(body['message'] ?? 'Failed to load productivity');
  }

  // ── GET /api/analytics/employee/:id ──────────────────────────────────
  Future<Map<String, dynamic>> getEmployeeDetail(String token, String employeeId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl$APIRouteAnalyticsEmployee$employeeId'),
      headers: HttpConstants.getHttpHeaders(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Failed to load employee analytics');
  }

  // ── GET /api/analytics/trends ─────────────────────────────────────────
  Future<List<TrendPoint>> getTrends(String token, {int days = 14}) async {
    final res = await _client.get(
      Uri.parse('$baseUrl$APIRouteAnalyticsTrends?days=$days'),
      headers: HttpConstants.getHttpHeaders(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return (body['data']['trendData'] as List)
          .map((t) => TrendPoint.fromJson(t))
          .toList();
    }
    throw Exception(body['message'] ?? 'Failed to load trends');
  }
}

// Plan gate 403 — show upgrade prompt instead of error
class PlanUpgradeRequired implements Exception {
  final String message;
  final String neededPlan;
  const PlanUpgradeRequired({required this.message, required this.neededPlan});
  @override
  String toString() => message;
}
