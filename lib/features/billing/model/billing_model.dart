// ─── Plan Info ────────────────────────────────────────────────────────────────
class PlanInfo {
  final String id;          // = slug ('starter','growth','business','enterprise')
  final String label;
  final int    monthlyPrice;
  final int    yearlyPrice;  // full-year lump sum
  final int    maxEmployees; // -1 = unlimited
  final int    maxManagers;  // -1 = unlimited
  final int    maxRooms;     // -1 = unlimited
  final int    historyDays;  // -1 = unlimited
  final bool   isContactSales;
  final bool   isActive;
  final Map<String, bool> features;
  final List<String>      featureLabels;

  const PlanInfo({
    required this.id,
    required this.label,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.maxEmployees,
    required this.maxManagers,
    required this.maxRooms,
    required this.historyDays,
    required this.isContactSales,
    required this.isActive,
    required this.features,
    required this.featureLabels,
  });

  bool get isFree => monthlyPrice == 0 && !isContactSales;

  /// Per-month equivalent when billed annually (for display)
  int get monthlyEquivalentAnnual =>
      yearlyPrice > 0 ? (yearlyPrice / 12).round() : 0;

  factory PlanInfo.fromJson(Map<String, dynamic> j) => PlanInfo(
    id:             j['slug'] as String,
    label:          j['label'] as String,
    monthlyPrice:   (j['monthlyPrice'] as num).toInt(),
    yearlyPrice:    (j['yearlyPrice'] as num).toInt(),
    maxEmployees:   (j['maxEmployees'] as num).toInt(),
    maxManagers:    (j['maxManagers'] as num).toInt(),
    maxRooms:       (j['maxRooms'] as num).toInt(),
    historyDays:    (j['historyDays'] as num).toInt(),
    isContactSales: j['isContactSales'] as bool? ?? false,
    isActive:       j['isActive'] as bool? ?? true,
    features:       Map<String, bool>.from(
      (j['features'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as bool)) ?? {},
    ),
    featureLabels: List<String>.from(j['featureLabels'] ?? []),
  );
}

// ─── Plan Limits (embedded in BillingStatus) ─────────────────────────────────
class PlanLimits {
  final int maxEmployees;
  final int maxManagers;
  final int maxRooms;
  final int historyDays;
  final Map<String, bool> features;

  const PlanLimits({
    required this.maxEmployees,
    required this.maxManagers,
    required this.maxRooms,
    required this.historyDays,
    required this.features,
  });

  bool hasFeature(String key) => features[key] ?? false;

  factory PlanLimits.fromJson(Map<String, dynamic> j) => PlanLimits(
    maxEmployees: (j['maxEmployees'] as num?)?.toInt() ?? 5,
    maxManagers:  (j['maxManagers']  as num?)?.toInt() ?? 1,
    maxRooms:     (j['maxRooms']     as num?)?.toInt() ?? 2,
    historyDays:  (j['historyDays']  as num?)?.toInt() ?? 30,
    features: Map<String, bool>.from(
      (j['features'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as bool)) ?? {},
    ),
  );
}

// ─── Billing Status ───────────────────────────────────────────────────────────
class BillingStatus {
  final String    plan;
  final String    effectivePlan;
  final bool      isTrialActive;
  final int       trialDaysLeft;
  final int       subscriptionDaysLeft;
  final DateTime? trialEndsAt;
  final DateTime? planExpiresAt;
  final int       billableSeats;
  final PlanLimits limits;

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
  });

  factory BillingStatus.fromJson(Map<String, dynamic> j) => BillingStatus(
    plan:                 j['plan'] as String,
    effectivePlan:        j['effectivePlan'] as String,
    isTrialActive:        j['isTrialActive'] as bool,
    trialDaysLeft:        (j['trialDaysLeft'] as num).toInt(),
    subscriptionDaysLeft: (j['subscriptionDaysLeft'] as num? ?? 0).toInt(),
    trialEndsAt:          j['trialEndsAt'] != null
        ? DateTime.parse(j['trialEndsAt']).toLocal() : null,
    planExpiresAt:        j['planExpiresAt'] != null
        ? DateTime.parse(j['planExpiresAt']).toLocal() : null,
    billableSeats:        (j['billableSeats'] as num).toInt(),
    limits: j['limits'] != null
        ? PlanLimits.fromJson(j['limits'] as Map<String, dynamic>)
        : PlanLimits(maxEmployees: 5, maxManagers: 1, maxRooms: 2,
        historyDays: 30, features: {}),
  );
}

// ─── Create Order Response ────────────────────────────────────────────────────
class CreateOrderResponse {
  final String orderId;
  final String subscriptionId;
  final int    totalAmountPaise;
  final int    totalAmountINR;
  final String razorpayKeyId;
  final String orgName;
  final String billingEmail;

  const CreateOrderResponse({
    required this.orderId,
    required this.subscriptionId,
    required this.totalAmountPaise,
    required this.totalAmountINR,
    required this.razorpayKeyId,
    required this.orgName,
    required this.billingEmail,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> j) =>
      CreateOrderResponse(
        orderId:          j['orderId'] as String,
        subscriptionId:   j['subscriptionId'] as String,
        totalAmountPaise: (j['totalAmountPaise'] as num).toInt(),
        totalAmountINR:   (j['totalAmountINR'] as num).toInt(),
        razorpayKeyId:    j['razorpayKeyId'] as String,
        orgName:          j['orgName'] as String,
        billingEmail:     j['billingEmail'] as String,
      );
}

// ─── Payment Record ───────────────────────────────────────────────────────────
class PaymentRecord {
  final String    id;
  final String    plan;
  final String    billingCycle;
  final double    amountINR;
  final String    status;
  final DateTime? paidAt;
  final DateTime? validUntil;

  const PaymentRecord({
    required this.id,
    required this.plan,
    required this.billingCycle,
    required this.amountINR,
    required this.status,
    this.paidAt,
    this.validUntil,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> j) => PaymentRecord(
    id:           j['id'] as String,
    plan:         j['plan'] as String,
    billingCycle: j['billingCycle'] as String,
    amountINR:    (j['amountINR'] as num).toDouble(),
    status:       j['status'] as String,
    paidAt:       j['paidAt'] != null ? DateTime.parse(j['paidAt']).toLocal() : null,
    validUntil:   j['validUntil'] != null ? DateTime.parse(j['validUntil']).toLocal() : null,
  );
}