import 'dart:convert';
import 'package:http/http.dart';
import '../../../config/constant/http_constants.dart';
import '../../../config/routes/api_routes.dart';
import '../../../core/http_client/http_client.dart';
import '../model/billing_model.dart';

class BillingDataSource {
  final Client _client = kHttpClient;
  final String baseUrl = HttpConstants.getBaseURL;

  // ── GET /api/billing/plans (public) ──────────────────────────────────
  Future<List<PlanInfo>> getPlans() async {
    final res = await _client.get(
      Uri.parse('$baseUrl$APIRouteBillingPlans'),
      headers: HttpConstants.getHttpHeaders(),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return (body['data'] as List)
          .map((p) => PlanInfo.fromJson(p))
          .toList();
    }
    throw Exception(body['message'] ?? 'Failed to load plans');
  }

  // ── GET /api/billing/status (manager) ────────────────────────────────
  Future<BillingStatus> getBillingStatus(String token) async {
    final res = await _client.get(
      Uri.parse('$baseUrl$APIRouteBillingStatus'),
      headers: HttpConstants.getHttpHeaders(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return BillingStatus.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to load billing status');
  }

  // ── POST /api/billing/create-order (manager) ─────────────────────────
  /// Returns the CreateOrderResponse containing razorpayKeyId, orderId, etc.
  Future<CreateOrderResponse> createOrder({
    required String token,
    required String plan,          // 'pro' | 'business'
    required String billingCycle,  // 'monthly' | 'annual'
    required String billingEmail,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl$APIRouteBillingCreateOrder'),
      headers: HttpConstants.getHttpHeaders(token),
      body: jsonEncode({
        'plan': plan,
        'billingCycle': billingCycle,
        'billingEmail': billingEmail,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return CreateOrderResponse.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to create order');
  }

  // ── POST /api/billing/verify-payment (manager) ───────────────────────
  /// Call this after Razorpay checkout succeeds.
  Future<Map<String, dynamic>> verifyPayment({
    required String token,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String subscriptionId,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl$APIRouteBillingVerifyPayment'),
      headers: HttpConstants.getHttpHeaders(token),
      body: jsonEncode({
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
        'subscriptionId': subscriptionId,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Payment verification failed');
  }

  // ── GET /api/billing/history (manager) ───────────────────────────────
  Future<List<PaymentRecord>> getHistory(String token) async {
    final res = await _client.get(
      Uri.parse('$baseUrl$APIRouteBillingHistory'),
      headers: HttpConstants.getHttpHeaders(token),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return (body['data'] as List)
          .map((p) => PaymentRecord.fromJson(p))
          .toList();
    }
    throw Exception(body['message'] ?? 'Failed to load payment history');
  }
}
