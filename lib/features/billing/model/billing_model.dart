// features/billing/model/billing_model.dart
// Maps to /api/billing/* responses

// ─── Plan Info (from GET /api/billing/plans) ─────────────────────────────────
class PlanInfo {
  final String id;           // 'starter' | 'pro' | 'business'
  final String label;
  final int? priceMonthly;   // null for free
  final int perSeatPrice;
  final int maxEmployees;
  final int maxRooms;
  final int historyDays;
  final bool gpsTrace;
  final bool exportReports;
  final bool productivityScores;

  const PlanInfo({
    required this.id,
    required this.label,
    this.priceMonthly,
    required this.perSeatPrice,
    required this.maxEmployees,
    required this.maxRooms,
    required this.historyDays,
    required this.gpsTrace,
    required this.exportReports,
    required this.productivityScores,
  });

  factory PlanInfo.fromJson(Map<String, dynamic> j) => PlanInfo(
    id: j['id'],
    label: j['label'],
    priceMonthly: j['priceMonthly'],
    perSeatPrice: j['perSeatPrice'] ?? 0,
    maxEmployees: j['maxEmployees'] ?? 20,
    maxRooms: j['maxRooms'] ?? 5,
    historyDays: j['historyDays'] ?? 7,
    gpsTrace: j['gpsTrace'] ?? false,
    exportReports: j['exportReports'] ?? false,
    productivityScores: j['productivityScores'] ?? false,
  );

  /// Monthly bill = base + (seats × perSeat)
  int monthlyTotal(int seats) =>
      (priceMonthly ?? 0) + seats * perSeatPrice;

  bool get isFree => priceMonthly == null || priceMonthly == 0;
}

// ─── Billing Status (from GET /api/billing/status) ────────────────────────────
class BillingStatus {
  final String plan;
  final String effectivePlan;
  final bool isTrialActive;
  final int trialDaysLeft;
  final int subscriptionDaysLeft;
  final DateTime? trialEndsAt;
  final DateTime? planExpiresAt;
  final int billableSeats;
  final PlanLimits limits;
  final LastPayment? lastPayment;

  const BillingStatus({
    required this.plan,
    required this.effectivePlan,
    required this.isTrialActive,
    required this.trialDaysLeft,
    required this.subscriptionDaysLeft,
    this.trialEndsAt,
    this.planExpiresAt,
    required this.billableSeats,
    required this.limits,
    this.lastPayment,
  });

  factory BillingStatus.fromJson(Map<String, dynamic> j) => BillingStatus(
    plan: j['plan'] ?? 'starter',
    effectivePlan: j['effectivePlan'] ?? 'starter',
    isTrialActive: j['isTrialActive'] ?? false,
    trialDaysLeft: j['trialDaysLeft'] ?? 0,
    subscriptionDaysLeft: j['subscriptionDaysLeft'] ?? 0,
    trialEndsAt: j['trialEndsAt'] != null
        ? DateTime.tryParse(j['trialEndsAt'])?.toLocal()
        : null,
    planExpiresAt: j['planExpiresAt'] != null
        ? DateTime.tryParse(j['planExpiresAt'])?.toLocal()
        : null,
    billableSeats: j['billableSeats'] ?? 0,
    limits: PlanLimits.fromJson(j['limits'] ?? {}),
    lastPayment: j['lastPayment'] != null
        ? LastPayment.fromJson(j['lastPayment'])
        : null,
  );

  bool get isPro     => effectivePlan == 'pro';
  bool get isBusiness => effectivePlan == 'business';
  bool get isEnterprise => effectivePlan == 'enterprise';
  bool get isFreeOnly  => effectivePlan == 'starter';
}

class PlanLimits {
  final int maxEmployees;
  final int maxRooms;
  final int historyDays;
  final bool gpsTrace;
  final bool exportReports;
  final bool productivityScores;

  const PlanLimits({
    required this.maxEmployees,
    required this.maxRooms,
    required this.historyDays,
    required this.gpsTrace,
    required this.exportReports,
    required this.productivityScores,
  });

  factory PlanLimits.fromJson(Map<String, dynamic> j) => PlanLimits(
    maxEmployees: j['maxEmployees'] ?? 20,
    maxRooms: j['maxRooms'] ?? 5,
    historyDays: j['historyDays'] ?? 7,
    gpsTrace: j['gpsTrace'] ?? false,
    exportReports: j['exportReports'] ?? false,
    productivityScores: j['productivityScores'] ?? false,
  );
}

class LastPayment {
  final String id;
  final double amount;
  final String status;
  final DateTime? validUntil;
  final DateTime? paidAt;

  const LastPayment({
    required this.id, required this.amount,
    required this.status, this.validUntil, this.paidAt,
  });

  factory LastPayment.fromJson(Map<String, dynamic> j) => LastPayment(
    id: j['id'] ?? '',
    amount: (j['amount'] ?? 0).toDouble(),
    status: j['status'] ?? '',
    validUntil: j['validUntil'] != null
        ? DateTime.tryParse(j['validUntil'])?.toLocal()
        : null,
    paidAt: j['paidAt'] != null
        ? DateTime.tryParse(j['paidAt'])?.toLocal()
        : null,
  );
}

// ─── Order Response (from POST /api/billing/create-order) ─────────────────────
class CreateOrderResponse {
  final String orderId;
  final String subscriptionId;
  final int totalAmountPaise;
  final int totalAmountINR;
  final String razorpayKeyId;
  final String orgName;
  final String billingEmail;
  final OrderBreakdown breakdown;

  const CreateOrderResponse({
    required this.orderId,
    required this.subscriptionId,
    required this.totalAmountPaise,
    required this.totalAmountINR,
    required this.razorpayKeyId,
    required this.orgName,
    required this.billingEmail,
    required this.breakdown,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> j) =>
      CreateOrderResponse(
        orderId: j['orderId'] ?? '',
        subscriptionId: j['subscriptionId'] ?? '',
        totalAmountPaise: j['totalAmountPaise'] ?? 0,
        totalAmountINR: j['totalAmountINR'] ?? 0,
        razorpayKeyId: j['razorpayKeyId'] ?? '',
        orgName: j['orgName'] ?? '',
        billingEmail: j['billingEmail'] ?? '',
        breakdown: OrderBreakdown.fromJson(j['breakdown'] ?? {}),
      );
}

class OrderBreakdown {
  final int basePlan;
  final int perSeat;
  final int seats;
  final String billingCycle;
  final String? discount;

  const OrderBreakdown({
    required this.basePlan, required this.perSeat,
    required this.seats, required this.billingCycle, this.discount,
  });

  factory OrderBreakdown.fromJson(Map<String, dynamic> j) => OrderBreakdown(
    basePlan: j['basePlan'] ?? 0,
    perSeat: j['perSeat'] ?? 0,
    seats: j['seats'] ?? 0,
    billingCycle: j['billingCycle'] ?? 'monthly',
    discount: j['discount'],
  );
}

// ─── Payment History record ────────────────────────────────────────────────────
class PaymentRecord {
  final String id;
  final String plan;
  final String billingCycle;
  final int seats;
  final double amountINR;
  final String status;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? paidAt;

  const PaymentRecord({
    required this.id, required this.plan, required this.billingCycle,
    required this.seats, required this.amountINR, required this.status,
    this.validFrom, this.validUntil, this.paidAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> j) => PaymentRecord(
    id: j['id'] ?? '',
    plan: j['plan'] ?? '',
    billingCycle: j['billingCycle'] ?? 'monthly',
    seats: j['seats'] ?? 0,
    amountINR: (j['amountINR'] ?? 0).toDouble(),
    status: j['status'] ?? '',
    validFrom: j['validFrom'] != null
        ? DateTime.tryParse(j['validFrom'])?.toLocal()
        : null,
    validUntil: j['validUntil'] != null
        ? DateTime.tryParse(j['validUntil'])?.toLocal()
        : null,
    paidAt: j['paidAt'] != null
        ? DateTime.tryParse(j['paidAt'])?.toLocal()
        : null,
  );
}
