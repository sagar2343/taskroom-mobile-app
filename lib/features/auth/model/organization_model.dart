class OrganizationModel {
  final String? id;
  final String? name;
  final String? code;
  final String? domain;
  final String? contactEmail;
  final String? contactPhone;
  final String? logo;
  final OrganizationAddress? address;
  final OrganizationSettings? settings;
  final OrganizationStats? stats;
  final bool? isActive;
  final bool? isSuspended;
  final String? suspensionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── NEW plan / billing fields ──────────────────────────────────────
  /// The stored plan: 'starter' | 'pro' | 'business' | 'enterprise'
  final String? plan;
  /// The effective plan — trial counts as 'pro' until trialEndsAt
  final String? effectivePlan;
  final DateTime? planExpiresAt;
  final DateTime? trialEndsAt;
  final bool? isTrialActive;
  final String? billingEmail;
  final int? billableSeats;

  OrganizationModel({
    this.id,
    this.name,
    this.code,
    this.domain,
    this.contactEmail,
    this.contactPhone,
    this.logo,
    this.address,
    this.settings,
    this.stats,
    this.isActive,
    this.isSuspended,
    this.suspensionReason,
    this.createdAt,
    this.updatedAt,
    // new
    this.plan,
    this.effectivePlan,
    this.planExpiresAt,
    this.trialEndsAt,
    this.isTrialActive,
    this.billingEmail,
    this.billableSeats,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['_id'],
      name: json['name'],
      code: json['code'],
      domain: json['domain'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      logo: json['logo'],
      address: json['address'] != null
          ? OrganizationAddress.fromJson(json['address'])
          : null,
      settings: json['settings'] != null
          ? OrganizationSettings.fromJson(json['settings'])
          : null,
      stats: json['stats'] != null
          ? OrganizationStats.fromJson(json['stats'])
          : null,
      isActive: json['isActive'],
      isSuspended: json['isSuspended'],
      suspensionReason: json['suspensionReason'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])?.toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])?.toLocal()
          : null,
      // new
      plan: json['plan'],
      effectivePlan: json['effectivePlan'],
      planExpiresAt: json['planExpiresAt'] != null
          ? DateTime.tryParse(json['planExpiresAt'])?.toLocal()
          : null,
      trialEndsAt: json['trialEndsAt'] != null
          ? DateTime.tryParse(json['trialEndsAt'])?.toLocal()
          : null,
      isTrialActive: json['isTrialActive'],
      billingEmail: json['billingEmail'],
      billableSeats: json['billableSeats'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'code': code,
      'domain': domain,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'logo': logo,
      'address': address?.toJson(),
      'settings': settings?.toJson(),
      'stats': stats?.toJson(),
      'isActive': isActive,
      'isSuspended': isSuspended,
      'suspensionReason': suspensionReason,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'plan': plan,
      'effectivePlan': effectivePlan,
      'planExpiresAt': planExpiresAt?.toUtc().toIso8601String(),
      'trialEndsAt': trialEndsAt?.toUtc().toIso8601String(),
      'isTrialActive': isTrialActive,
      'billingEmail': billingEmail,
      'billableSeats': billableSeats,
    };
  }

  /// Convenience: true while in trial period
  bool get isInTrial => (isTrialActive == true) &&
      trialEndsAt != null &&
      DateTime.now().isBefore(trialEndsAt!);

  /// Convenience: trial days left (0 if expired / not in trial)
  int get trialDaysLeft {
    if (!isInTrial || trialEndsAt == null) return 0;
    return trialEndsAt!.difference(DateTime.now()).inDays.clamp(0, 99);
  }

  /// True if on paid Pro, Business, or Enterprise
  bool get isPaid =>
      plan != null && plan != 'starter' && isTrialActive != true;
}

// ─────────────────────────────────────────────────────────────────────────────

class OrganizationAddress {
  final String? street;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;

  OrganizationAddress({
    this.street, this.city, this.state, this.pincode, this.country,
  });

  factory OrganizationAddress.fromJson(Map<String, dynamic> json) {
    return OrganizationAddress(
      street: json['street'], city: json['city'],
      state: json['state'],   pincode: json['pincode'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() => {
    'street': street, 'city': city, 'state': state,
    'pincode': pincode, 'country': country,
  };
}

class OrganizationSettings {
  final int? maxEmployees;
  final int? maxRooms;
  final bool? enableLocationTracking;

  OrganizationSettings({
    this.maxEmployees, this.maxRooms, this.enableLocationTracking,
  });

  factory OrganizationSettings.fromJson(Map<String, dynamic> json) {
    return OrganizationSettings(
      maxEmployees: json['maxEmployees'],
      maxRooms: json['maxRooms'],
      enableLocationTracking: json['enableLocationTracking'],
    );
  }

  Map<String, dynamic> toJson() => {
    'maxEmployees': maxEmployees,
    'maxRooms': maxRooms,
    'enableLocationTracking': enableLocationTracking,
  };
}

class OrganizationStats {
  final int? totalEmployees;
  final int? totalManagers;
  final int? totalRooms;
  final int? totalTasks;
  final int? totalTasksCompleted;

  OrganizationStats({
    this.totalEmployees, this.totalManagers, this.totalRooms,
    this.totalTasks, this.totalTasksCompleted,
  });

  factory OrganizationStats.fromJson(Map<String, dynamic> json) {
    return OrganizationStats(
      totalEmployees: json['totalEmployees'],
      totalManagers: json['totalManagers'],
      totalRooms: json['totalRooms'],
      totalTasks: json['totalTasks'],
      totalTasksCompleted: json['totalTasksCompleted'],
    );
  }

  Map<String, dynamic> toJson() => {
    'totalEmployees': totalEmployees,
    'totalManagers': totalManagers,
    'totalRooms': totalRooms,
    'totalTasks': totalTasks,
    'totalTasksCompleted': totalTasksCompleted,
  };
}
