import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_pallete.dart';
import '../../controller/billing_controller.dart';
import '../../model/billing_model.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  late final BillingController _ctrl;
  String _selectedCycle = 'monthly';

  @override
  void initState() {
    super.initState();
    _ctrl = BillingController(
      context:    context,
      reloadData: () { if (mounted) setState(() {}); },
    );
    _ctrl.init();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── helpers that use Theme ────────────────────────────────────────────────
  Color get _surface   => Theme.of(context).colorScheme.surface;
  Color get _bg        => Theme.of(context).scaffoldBackgroundColor;
  Color get _border    => Theme.of(context).colorScheme.outline.withValues(alpha: 0.25);
  Color get _textPrim  => Theme.of(context).colorScheme.onSurface;
  Color get _textSec   => Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding:    const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        _textPrim.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: _textPrim),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Plans & Billing',
            style: Theme.of(context).textTheme.titleMedium!
                .copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _ctrl.loadAll,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _ctrl.isLoading && _ctrl.status == null
          ? Center(child: CircularProgressIndicator(color: Pallete.primaryColor))
          : RefreshIndicator(
            onRefresh: _ctrl.loadAll,
            color: Pallete.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusBanner(ctrl: _ctrl),
                  const SizedBox(height: 20),
                  _CycleToggle(
                    selected: _selectedCycle,
                    onChanged: (v) => setState(() => _selectedCycle = v),
                  ),
                  const SizedBox(height: 16),
                  if (_ctrl.plans.isEmpty && !_ctrl.isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('Loading plans…',
                            style: TextStyle(color: _textSec)),
                      ),
                    )
                  else
                    ..._ctrl.plans.map((plan) => _PlanCard(
                      plan:                 plan,
                      billingCycle:         _selectedCycle,
                      seats:                _ctrl.status?.billableSeats ?? 0,
                      currentEffectivePlan: _ctrl.status?.effectivePlan ?? 'starter',
                      isTrialActive:        _ctrl.status?.isTrialActive ?? false,
                      isProcessing:         _ctrl.isProcessing,
                      onUpgrade: (email) => _ctrl.startUpgrade(
                        plan:         plan.id,
                        billingCycle: _selectedCycle,
                        billingEmail: email,
                      ),
                    )),
                  const SizedBox(height: 28),
                  if (_ctrl.history.isNotEmpty) ...[
                    Text('Payment History',
                        style: Theme.of(context).textTheme.titleSmall!
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ..._ctrl.history.map((r) => _PaymentTile(record: r)),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }
}

// ─── Status Banner ────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final BillingController ctrl;
  const _StatusBanner({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.status;
    if (s == null) return const SizedBox.shrink();

    final inTrial = s.isTrialActive && s.trialDaysLeft > 0;
    final isPaid  = !s.isTrialActive && s.plan != 'starter';

    Color accent;
    String title, subtitle;
    IconData icon;

    if (inTrial) {
      accent   = Pallete.primaryColor;
      icon     = Icons.hourglass_top_rounded;
      title    = '14-day Pro Trial — ${s.trialDaysLeft} day${s.trialDaysLeft == 1 ? "" : "s"} left';
      subtitle = 'Enjoying all Pro features. Upgrade before trial ends to keep access.';
    } else if (isPaid) {
      accent   = Pallete.successColor;
      icon     = Icons.verified_rounded;
      title    = '${_cap(s.effectivePlan)} Plan — Active';
      subtitle = s.planExpiresAt != null
          ? 'Valid until ${DateFormat("d MMM yyyy").format(s.planExpiresAt!)}  •  ${s.billableSeats} seats'
          : '${s.billableSeats} billable seats';
    } else {
      accent   = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
      icon     = Icons.info_outline_rounded;
      title    = 'Free Starter Plan';
      subtitle = 'Up to 20 employees, 7-day history, basic features only.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:  accent.withValues(alpha: 0.07),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color:        accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(color: accent,
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.55),
                    fontSize: 12)),
          ],
        )),
      ]),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Cycle Toggle ─────────────────────────────────────────────────────────────
class _CycleToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _CycleToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        _btn(context, 'monthly', 'Monthly'),
        _btn(context, 'annual',  'Annual  –20%'),
      ]),
    );
  }

  Widget _btn(BuildContext ctx, String value, String label) {
    final sel = selected == value;
    return Expanded(child: GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:        sel ? Pallete.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:      sel ? Colors.white
                : Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
            fontSize:   13,
          ),
        ),
      ),
    ));
  }
}

// ─── Plan Card ────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final PlanInfo plan;
  final String   billingCycle;
  final int      seats;
  final String   currentEffectivePlan;
  final bool     isTrialActive;
  final bool     isProcessing;
  final void Function(String billingEmail) onUpgrade;

  const _PlanCard({
    required this.plan,
    required this.billingCycle,
    required this.seats,
    required this.currentEffectivePlan,
    required this.isTrialActive,
    required this.isProcessing,
    required this.onUpgrade,
  });

  // Plan upgrade logic:
  // - Show button if plan is higher rank than current effective plan
  // - ALSO show button if current is on trial (trial is 'pro' effective)
  //   but they haven't actually paid for pro yet → allow purchasing pro
  bool get _showUpgrade {
    if (plan.isFree) return false;
    final currentRank = _rank(currentEffectivePlan);
    final planRank    = _rank(plan.id);

    // If on trial (effectivePlan = 'pro' from trial), still allow buying pro
    if (isTrialActive && plan.id == 'pro') return true;

    return planRank > currentRank;
  }

  int _rank(String p) => switch (p) {
    'starter'    => 0, 'pro'        => 1,
    'business'   => 2, 'enterprise' => 3, _ => 0,
  };

  bool get _isCurrent =>
      currentEffectivePlan == plan.id && !isTrialActive;

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = plan.monthlyTotal(seats);
    final annualTotal  = (monthlyTotal * 12 * 0.8).round();
    final displayPrice = billingCycle == 'annual'
        ? (annualTotal / 12).round()
        : monthlyTotal;

    final borderColor = _isCurrent
        ? Pallete.primaryColor
        : (isTrialActive && plan.id == 'pro')
        ? Pallete.successColor
        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:  Theme.of(context).colorScheme.surface,
        border: Border.all(color: borderColor, width: _isCurrent ? 2 : 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(plan.label,
                        style: Theme.of(context).textTheme.titleSmall!
                            .copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    if (_isCurrent)
                      _badge('Current', Pallete.primaryColor),
                    if (isTrialActive && plan.id == 'pro')
                      _badge('Trial Active', Pallete.successColor),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    plan.isFree
                        ? 'Free forever'
                        : '₹${_fmt(displayPrice)}/mo${billingCycle == "annual" ? " · billed annually" : ""}',
                    style: TextStyle(
                        color: Pallete.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  if (!plan.isFree && seats > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '₹${_fmt(plan.priceMonthly ?? 0)} base + ₹${plan.perSeatPrice}×$seats seats = ₹${_fmt(monthlyTotal)}/mo',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.4),
                          fontSize: 11),
                    ),
                  ],
                ],
              )),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Feature chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            _featureChip(context, 'Up to ${plan.maxEmployees == 999999 ? "∞" : plan.maxEmployees} employees', true),
            _featureChip(context, '${plan.historyDays == 999999 ? "∞" : plan.historyDays}-day history', true),
            _featureChip(context, 'GPS trace',           plan.gpsTrace),
            _featureChip(context, 'Export PDF/Excel',    plan.exportReports),
            _featureChip(context, 'Productivity scores', plan.productivityScores),
          ]),
        ),
        const SizedBox(height: 16),

        // CTA button
        if (_showUpgrade) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: isProcessing ? null : () => _showEmailDialog(context),
                child: isProcessing
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : Text(
                    isTrialActive && plan.id == 'pro'
                        ? 'Buy Pro — Keep Access'
                        : 'Upgrade to ${plan.label} →',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
        ],
      ]),
    );
  }

  void _showEmailDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Upgrade to ${plan.label}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Enter the email for your billing receipt:',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.6),
                  fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'billing@yourcompany.com',
              filled:   true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Pallete.primaryColor, width: 2),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Pallete.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              final email = emailCtrl.text.trim();
              Navigator.pop(context);
              if (email.isNotEmpty) onUpgrade(email);
            },
            child: const Text('Continue to Payment'),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(100),
      border:       Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Widget _featureChip(BuildContext ctx, String label, bool enabled) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: enabled
          ? Pallete.primaryColor.withValues(alpha: 0.1)
          : Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(label,
        style: TextStyle(
          color: enabled ? Pallete.primaryColor
              : Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.35),
          fontSize: 11, fontWeight: FontWeight.w500,
        )),
  );

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ─── Payment Tile ─────────────────────────────────────────────────────────────
class _PaymentTile extends StatelessWidget {
  final PaymentRecord record;
  const _PaymentTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final isPaid = record.status == 'paid';
    final color  = isPaid ? Pallete.successColor : Pallete.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:  Theme.of(context).colorScheme.surface,
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPaid ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color, size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_cap(record.plan)} — ${_cap(record.billingCycle)}',
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(fontWeight: FontWeight.w600)),
            Text(
              record.paidAt != null
                  ? DateFormat('d MMM yyyy').format(record.paidAt!)
                  : _cap(record.status),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.5),
                  fontSize: 12),
            ),
          ],
        )),
        Text('₹${record.amountINR.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium!
                .copyWith(fontWeight: FontWeight.w700)),
      ]),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
