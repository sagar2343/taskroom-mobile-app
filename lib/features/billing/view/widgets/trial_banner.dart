import 'package:flutter/material.dart';
import '../../../../config/data/local/app_data.dart';
import '../../../../config/theme/app_pallete.dart';
import '../../data/billing_datasource.dart';
import '../../model/billing_model.dart';
import '../screen/billing_screen.dart';

class TrialBanner extends StatefulWidget {
  const TrialBanner({super.key});

  @override
  State<TrialBanner> createState() => _TrialBannerState();
}

class _TrialBannerState extends State<TrialBanner> {
  final _ds = BillingDataSource();
  BillingStatus? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final token = AppData().getAccessToken();
      if (token == null) return;
      final s = await _ds.getBillingStatus(token);
      if (mounted) setState(() => _status = s);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    if (s == null) return const SizedBox.shrink();
    final expiringSoon = !s.isTrialActive && s.subscriptionDaysLeft > 0 && s.subscriptionDaysLeft <= 7;
    // if (!s.isTrialActive && s.plan != 'starter') return const SizedBox.shrink();
    if (!s.isTrialActive && s.plan != 'starter' && !expiringSoon) {
      return const SizedBox.shrink();
    }

    final inTrial = s.isTrialActive && s.trialDaysLeft > 0;
    final expired = s.isTrialActive && s.trialDaysLeft == 0;

    Color accent;
    String message, cta;
    IconData icon;

    if (inTrial) {
      accent  = Pallete.primaryColor;
      icon    = Icons.hourglass_top_rounded;
      message = '${s.trialDaysLeft} day${s.trialDaysLeft == 1 ? "" : "s"} left in your free Pro trial';
      cta     = 'Upgrade';
    } else if (expired) {
      accent  = Pallete.errorColor;
      icon    = Icons.lock_outline_rounded;
      message = 'Trial ended — Pro features are now locked';
      cta     = 'Choose plan';
    } else if (expiringSoon) {
      accent  = Colors.orange;
      icon    = Icons.warning_amber_rounded;
      message =
      'Your ${s.plan} plan expires in ${s.subscriptionDaysLeft} day${s.subscriptionDaysLeft == 1 ? "" : "s"}';
      cta     = 'Renew';
    } else {
      accent  = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
      icon    = Icons.info_outline_rounded;
      message = "You're on the free Starter plan";
      cta     = 'Upgrade';
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BillingScreen()),
      ).then((_) => _loadStatus()),
      child: Container(
        margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:  accent.withValues(alpha: 0.08),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: 12, fontWeight: FontWeight.w500))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:        accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(cta,
                style: TextStyle(color: accent,
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
