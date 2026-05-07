import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../config/data/local/app_data.dart';
import '../../../core/utils/helpers.dart';
import '../data/billing_datasource.dart';
import '../model/billing_model.dart';

class BillingController {
  final BuildContext context;
  final VoidCallback reloadData;

  final _ds = BillingDataSource();

  // ── State ──────────────────────────────────────────────────────────────────
  bool isLoading    = false;
  bool isProcessing = false; // true while Razorpay checkout is open
  String? errorMsg;

  List<PlanInfo>   plans   = [];
  BillingStatus?   status;
  List<PaymentRecord> history = [];

  // Tracks which plan is being purchased during checkout
  String? _pendingPlan;
  String? _pendingCycle;
  String? _pendingSubscriptionId;

  late final Razorpay _razorpay;

  BillingController({required this.context, required this.reloadData}) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() => loadAll();

  Future<void> loadAll() async {
    await Future.wait([loadPlans(), loadStatus(), loadHistory()]);
  }

  // ── Data loaders ──────────────────────────────────────────────────────────

  Future<void> loadPlans() async {
    isLoading = true;
    reloadData();
    try {
      plans = await _ds.getPlans();
    } catch (e) {
      errorMsg = e.toString();
    } finally {
      isLoading = false;
      reloadData();
    }
  }

  Future<void> loadStatus() async {
    try {
      final token = AppData().getAccessToken();
      if (token == null) return;
      status = await _ds.getBillingStatus(token);
    } catch (e) {
      errorMsg = e.toString();
    }
    reloadData();
  }

  Future<void> loadHistory() async {
    try {
      final token = AppData().getAccessToken();
      if (token == null) return;
      history = await _ds.getHistory(token);
    } catch (e) {
      // non-fatal — silently ignore
      debugPrint('billing history error: $e');
    }
    reloadData();
  }

  // ── Upgrade flow ──────────────────────────────────────────────────────────
  Future<void> startUpgrade({
    required String plan,
    required String billingCycle,
    required String billingEmail,
  }) async {
    if (isProcessing) return;

    try {
      isProcessing = true;
      errorMsg = null;
      reloadData();

      final token = AppData().getAccessToken();
      if (token == null) throw Exception('Not authenticated');

      // 1. Create order on backend
      final order = await _ds.createOrder(
        token: token,
        plan: plan,
        billingCycle: billingCycle,
        billingEmail: billingEmail,
      );

      _pendingPlan           = plan;
      _pendingCycle          = billingCycle;
      _pendingSubscriptionId = order.subscriptionId;

      // 2. Open Razorpay checkout
      _razorpay.open({
        'key':         order.razorpayKeyId,
        'amount':      order.totalAmountPaise,
        'currency':    'INR',
        'name':        'TaskRoom',
        'order_id':    order.orderId,
        'description': '${_planLabel(plan)} Plan — $billingCycle',
        'prefill': {
          'email':   billingEmail,
          'contact': AppData().getUserData()?.mobile ?? '',
        },
        'theme': {'color': '#137fec'},
        'notes': {'plan': plan, 'billingCycle': billingCycle},
      });
    } catch (e) {
      isProcessing = false;
      errorMsg = e.toString();
      reloadData();
      _snack('Payment Error: ${e.toString()}');
    }
  }

  // ── Razorpay callbacks ────────────────────────────────────────────────────
  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final token = AppData().getAccessToken();
      if (token == null) throw Exception('Not authenticated');

      if (response.orderId == null ||
          response.paymentId == null ||
          response.signature == null ||
          _pendingSubscriptionId == null) {
        throw Exception('Incomplete payment response from Razorpay');
      }

      // 3. Verify with backend — upgrades org plan
      await _ds.verifyPayment(
        token:              token,
        razorpayOrderId:   response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
        subscriptionId:    _pendingSubscriptionId!,
      );

      // Refresh status so UI reflects the new plan immediately
      await loadStatus();

      _snack(
        '🎉 You are now on the ${_planLabel(_pendingPlan ?? "")} plan!',
        success: true,
      );
    } catch (e) {
      errorMsg = e.toString();
      _snack('Verification Error: ${e.toString()}');
    } finally {
      isProcessing = false;
      _pendingPlan           = null;
      _pendingCycle          = null;
      _pendingSubscriptionId = null;
      reloadData();
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    isProcessing     = false;
    _pendingPlan     = null;
    _pendingCycle    = null;
    _pendingSubscriptionId = null;
    reloadData();
    _snack(response.message ?? 'Payment was not completed.');
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    isProcessing = false;
    reloadData();
    _snack('External wallet selected: ${response.walletName ?? ""}');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _planLabel(String plan) => switch (plan) {
    'pro'        => 'Pro',
    'business'   => 'Business',
    'enterprise' => 'Enterprise',
    _            => 'Starter',
  };

  PlanInfo? planById(String id) {
    try { return plans.firstWhere((p) => p.id == id); }
    catch (_) { return null; }
  }

  bool hasFeature(String feature) {
    final s = status;
    if (s == null) return false;
    return switch (feature) {
      'gpsTrace'           => s.limits.gpsTrace,
      'exportReports'      => s.limits.exportReports,
      'productivityScores' => s.limits.productivityScores,
      _                    => false,
    };
  }

  void _snack(String msg, {bool success = false}) {
    if (!context.mounted) return;
    Helpers.showSnackBar(
      context, msg,
      type: success ? SnackType.success : SnackType.error,
    );
  }

  void dispose() {
    _razorpay.clear();
  }
}
